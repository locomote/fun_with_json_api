module FunWithJsonApi
  module SchemaValidators
    class CheckRelationships
      def self.call(document, deserializer)
        new(document, deserializer).call
      end

      attr_reader :document
      attr_reader :deserializer

      def initialize(document, deserializer)
        @document = document
        @deserializer = deserializer
      end

      def call
        relationships = document['data'].fetch('relationships', {})

        check_for_unknown_relationships! relationships.keys
        check_for_invalid_relationship_type! relationships

        true
      end

      def check_for_unknown_relationships!(relationship_keys)
        unknown = relationship_keys.reject { |rel| resource_relationships.include?(rel) }
        return if unknown.empty?

        raise build_unknown_relationship_error(unknown)
      end

      def check_for_invalid_relationship_type!(relationships_hash)
        payload = build_invalid_relationship_type_payload(relationships_hash)
        return if payload.empty?

        message = 'A relationship received data with an incorrect type'
        raise FunWithJsonApi::Exceptions::InvalidRelationshipType.new(message, payload)
      end

      def check_for_invalid_relationship_type_in_collection!(relationship, collection_data)
        return unless collection_data.is_a?(Array)

        collection_data.each_with_index.map do |item, index|
          next if item['type'] == relationship.type

          build_invalid_collection_item_payload(relationship, index)
        end
      end

      def check_for_invalid_relationship_type_in_relationship!(relationship, relationship_data)
        return unless relationship_data.is_a?(Hash)
        return if relationship_data['type'] == relationship.type

        build_invalid_relationship_item_payload(relationship)
      end

      def resource_relationships
        @resource_relationships ||= deserializer.relationships.map(&:name).map(&:to_s)
      end

      private

      def invalid_relationship_type_in_array_message(relationship)
        I18n.t(
          :invalid_relationship_type_in_array,
          relationship: relationship.name,
          relationship_type: relationship.type,
          scope: 'fun_with_json_api.schema_validators'
        )
      end

      def invalid_relationship_type_in_hash_message(relationship)
        I18n.t(
          :invalid_relationship_type_in_hash,
          relationship: relationship.name,
          relationship_type: relationship.type,
          scope: 'fun_with_json_api.schema_validators'
        )
      end

      def build_invalid_relationship_type_payload(relationships_hash)
        deserializer.relationships.map do |relationship|
          data = relationships_hash.fetch(relationship.name.to_s, 'data' => nil)['data']
          if relationship.has_many?
            check_for_invalid_relationship_type_in_collection!(relationship, data)
          else
            check_for_invalid_relationship_type_in_relationship!(relationship, data)
          end
        end.flatten.compact
      end

      def build_invalid_collection_item_payload(relationship, index)
        ExceptionPayload.new(
          detail: invalid_relationship_type_in_array_message(relationship),
          pointer: "/data/relationships/#{relationship.name}/data/#{index}/type"
        )
      end

      def build_invalid_relationship_item_payload(relationship)
        ExceptionPayload.new(
          detail: invalid_relationship_type_in_hash_message(relationship),
          pointer: "/data/relationships/#{relationship.name}/data/type"
        )
      end

      def build_unknown_relationship_error(unknown_relationships)
        payload = unknown_relationships.map do |relationship|
          ExceptionPayload.new(
            detail: unknown_relationship_error(relationship),
            pointer: "/data/relationships/#{relationship}"
          )
        end
        message = 'Unknown relationships were provided by endpoint'
        FunWithJsonApi::Exceptions::UnknownRelationship.new(message, payload)
      end

      def unknown_relationship_error(relationship)
        I18n.t(
          :unknown_relationship_for_resource,
          relationship: relationship,
          resource: deserializer.type,
          scope: 'fun_with_json_api.schema_validators'
        )
      end
    end
  end
end
