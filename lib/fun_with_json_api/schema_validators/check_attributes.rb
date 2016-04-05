module FunWithJsonApi
  module SchemaValidators
    class CheckAttributes
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
        attributes = document['data'].fetch('attributes', {}).keys
        unknown = attributes.reject { |attribute| resource_attributes.include?(attribute) }

        return true if unknown.empty?

        raise build_unknown_attribute_error(unknown)
      end

      def resource_attributes
        @resource_attributes ||= deserializer.attributes.map(&:name).map(&:to_s)
      end

      def known_attributes
        @known_attributes ||= deserializer.class.attribute_names.map(&:to_s)
      end

      private

      def build_unknown_attribute_error(unknown_attributes)
        payload = unknown_attributes.map do |attribute|
          if known_attributes.include?(attribute)
            build_forbidden_attribute_payload(attribute)
          else
            build_unknown_attribute_payload(attribute)
          end
        end
        message = 'Unknown attributes were provided by endpoint'
        FunWithJsonApi::Exceptions::UnknownAttribute.new(message, payload)
      end

      def build_unknown_attribute_payload(attribute)
        ExceptionPayload.new(
          detail: unknown_attribute_error(attribute),
          pointer: "/data/attributes/#{attribute}"
        )
      end

      def build_forbidden_attribute_payload(attribute)
        ExceptionPayload.new(
          detail: forbidden_attribute_error(attribute),
          pointer: "/data/attributes/#{attribute}",
          status: '403'
        )
      end

      def unknown_attribute_error(attribute)
        I18n.t(
          :unknown_attribute_for_resource,
          attribute: attribute,
          resource: deserializer.type,
          scope: 'fun_with_json_api.schema_validators'
        )
      end

      def forbidden_attribute_error(attribute)
        I18n.t(
          :forbidden_attribute_for_request,
          attribute: attribute,
          resource: deserializer.type,
          scope: 'fun_with_json_api.schema_validators'
        )
      end
    end
  end
end
