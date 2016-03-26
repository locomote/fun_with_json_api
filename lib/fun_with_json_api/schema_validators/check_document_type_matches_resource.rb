module FunWithJsonApi
  module SchemaValidators
    class CheckDocumentTypeMatchesResource
      def self.call(schema_validator)
        new(schema_validator).call
      end

      attr_reader :schema_validator
      delegate :document_type,
               :resource_type,
               :deserializer,
               to: :schema_validator

      def initialize(schema_validator)
        @schema_validator = schema_validator
      end

      def call
        if document_type != resource_type
          message = "'#{document_type}' does not match the expected resource"\
                    ": #{resource_type}"
          payload = ExceptionPayload.new(
            detail: document_type_does_not_match_endpoint_message
          )
          raise Exceptions::InvalidDocumentType.new(message, payload)
        end
      end

      private

      def document_type_does_not_match_endpoint_message
        I18n.t(
          :document_type_does_not_match_endpoint,
          expected: resource_type,
          scope: 'fun_with_json_api.schema_validators'
        )
      end
    end
  end
end
