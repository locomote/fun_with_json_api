module FunWithJsonApi
  module SchemaValidators
    class CheckRelationships
      def self.call(api_document, deserializer)
        new(api_document, deserializer).call
      end

      attr_reader :api_document
      attr_reader :deserializer

      def initialize(api_document, deserializer)
        @api_document = api_document
        @deserializer = deserializer
      end

      def call
        relationships = api_document['data'].fetch('relationships', {}).keys
        unknown = relationships.reject { |rel| resource_relationships.include?(rel) }

        return true if unknown.empty?

        raise build_unknown_relationship_error(unknown)
      end

      def resource_relationships
        @resource_relationships ||= deserializer.relationships.map(&:name).map(&:to_s)
      end

      private

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
