module FunWithJsonApi
  module SchemaValidators
    class CheckAttributes
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
        attributes = api_document['data'].fetch('attributes', {}).keys
        unknown = attributes.reject { |attribute| resource_attributes.include?(attribute) }

        return true if unknown.empty?

        raise build_unknown_attribute_error(unknown)
      end

      def resource_attributes
        @resource_attributes ||= deserializer.attributes.map(&:name).map(&:to_s)
      end

      private

      def build_unknown_attribute_error(unknown_attributes)
        payload = unknown_attributes.map do |attribute|
          ExceptionPayload.new(
            detail: unknown_attribute_error(attribute),
            pointer: "/data/attributes/#{attribute}"
          )
        end
        message = 'Unknown attributes were provided by endpoint'
        FunWithJsonApi::Exceptions::UnknownAttribute.new(message, payload)
      end

      def unknown_attribute_error(attribute)
        I18n.t(
          :unknown_attribute_for_resource,
          attribute: attribute,
          resource: deserializer.type,
          scope: 'fun_with_json_api.schema_validators'
        )
      end
    end
  end
end
