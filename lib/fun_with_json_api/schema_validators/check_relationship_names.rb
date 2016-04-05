module FunWithJsonApi
  module SchemaValidators
    # Ensures all provided relationship names are known
    class CheckRelationshipNames
      def self.call(*args)
        new(*args).call
      end

      attr_reader :document
      attr_reader :deserializer
      attr_reader :relationship_keys

      def initialize(document, deserializer, relationship_keys)
        @document = document
        @deserializer = deserializer
        @relationship_keys = relationship_keys
      end

      def call
        unknown = relationship_keys.reject { |rel| resource_relationships.include?(rel) }
        return if unknown.empty?

        raise build_unknown_relationship_error(unknown)
      end

      protected

      def build_unknown_relationship_error(unknown_relationships)
        payload = unknown_relationships.map do |relationship|
          if known_relationships.include?(relationship)
            build_forbidden_relationship_payload(relationship)
          else
            build_unknown_relationship_payload(relationship)
          end
        end
        message = 'Unknown relationships were provided by endpoint'
        FunWithJsonApi::Exceptions::UnknownRelationship.new(message, payload)
      end

      def resource_relationships
        @resource_relationships ||= deserializer.relationships.map(&:name).map(&:to_s)
      end

      def known_relationships
        @known_relationships ||= deserializer.class.relationship_names.map(&:to_s)
      end

      private

      # Relationship is known, but not supported by this request
      def build_forbidden_relationship_payload(relationship)
        ExceptionPayload.new(
          detail: forbidden_relationship_error(relationship),
          pointer: "/data/relationships/#{relationship}",
          status: '403'
        )
      end

      # Relationship is completely unknown, can cannot be assigned to this resource type (ever!)
      def build_unknown_relationship_payload(relationship)
        ExceptionPayload.new(
          detail: unknown_relationship_error(relationship),
          pointer: "/data/relationships/#{relationship}"
        )
      end

      def unknown_relationship_error(relationship)
        I18n.t(
          :unknown_relationship_for_resource,
          relationship: relationship,
          resource: deserializer.type,
          scope: 'fun_with_json_api.schema_validators'
        )
      end

      def forbidden_relationship_error(relationship)
        I18n.t(
          :forbidden_relationship_for_request,
          relationship: relationship,
          resource: deserializer.type,
          scope: 'fun_with_json_api.schema_validators'
        )
      end
    end
  end
end
