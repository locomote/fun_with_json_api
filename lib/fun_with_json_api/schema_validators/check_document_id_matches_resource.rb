module FunWithJsonApi
  module SchemaValidators
    class CheckDocumentIdMatchesResource
      def self.call(schema_validator)
        new(schema_validator).call
      end

      attr_reader :schema_validator
      delegate :resource,
               :document_id,
               :resource_id,
               :resource_type,
               :deserializer,
               to: :schema_validator

      def initialize(schema_validator)
        @schema_validator = schema_validator
      end

      def call
        if resource.try(:persisted?)
          # Ensure correct update document is being sent
          check_resource_id_is_a_string
          check_resource_id_matches_document_id
        elsif document_id
          # Ensure correct create document is being sent
          check_resource_id_is_a_string
          check_resource_id_can_be_client_generated
          check_resource_id_has_not_already_been_used
        end
      end

      def check_resource_id_is_a_string
        unless document_id.is_a?(String)
          payload = ExceptionPayload.new(
            detail: document_id_is_not_a_string_message,
            pointer: '/data/id'
          )
          message = "document id is not a string: #{document_id.class.name}"
          raise Exceptions::InvalidDocumentIdentifier.new(message, payload)
        end
      end

      def check_resource_id_matches_document_id
        if document_id != resource_id
          message = "resource id '#{resource_id}' does not match the expected id for"\
                    " '#{resource_type}': '#{document_id}'"
          payload = ExceptionPayload.new(
            detail: document_id_does_not_match_resource_message
          )
          raise Exceptions::InvalidDocumentIdentifier.new(message, payload)
        end
      end

      def check_resource_id_can_be_client_generated
        # Ensure id has been provided as an attribute
        if deserializer.attributes.none? { |attribute| attribute.name == :id }
          deserializer_name = deserializer.class.name || 'Deserializer'
          message = "id parameter for '#{resource_type}' cannot be set"\
                    " as it has not been defined as a #{deserializer_name} attribute"
          payload = ExceptionPayload.new(
            detail: resource_id_can_not_be_client_generated_message
          )
          raise Exceptions::IllegalClientGeneratedIdentifier.new(message, payload)
        end
      end

      def check_resource_id_has_not_already_been_used
        if (existing = deserializer.load_resource_from_id_value(document_id))
          deserializer_class = deserializer.class.name || 'Deserializer'
          message = "#{deserializer_class}#load_resource_from_id_value for '#{resource_type}' has"\
                    ' found a existing resource matching document id'\
                    ": #{existing.class.name}##{existing.id}"
          payload = ExceptionPayload.new(
            detail: resource_id_has_already_been_used_message
          )
          raise Exceptions::InvalidClientGeneratedIdentifier.new(message, payload)
        end
      end

      private

      def document_id_is_not_a_string_message
        I18n.t(
          :document_id_is_not_a_string_message,
          scope: 'fun_with_json_api.schema_validators'
        )
      end

      def document_id_does_not_match_resource_message
        I18n.t(
          :document_id_does_not_match_resource,
          expected: resource_id,
          scope: 'fun_with_json_api.schema_validators'
        )
      end

      def resource_id_can_not_be_client_generated_message
        I18n.t(
          :resource_id_can_not_be_client_generated,
          resource: resource_type,
          scope: 'fun_with_json_api.schema_validators'
        )
      end

      def resource_id_has_already_been_used_message
        I18n.t(
          :resource_id_has_already_been_assigned,
          id: document_id,
          resource: resource_type,
          scope: 'fun_with_json_api.schema_validators'
        )
      end
    end
  end
end
