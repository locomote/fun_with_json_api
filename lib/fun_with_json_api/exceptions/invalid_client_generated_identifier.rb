module FunWithJsonApi
  module Exceptions
    # A server MUST return 409 Conflict when processing a POST request to create a resource with a
    # client-generated ID that already exists.
    class InvalidClientGeneratedIdentifier < FunWithJsonApi::Exception
      EXCEPTION_CODE = 'invalid_client_generated_identifier'.freeze

      def initialize(message, payload = ExceptionPayload.new)
        payload.code ||= EXCEPTION_CODE
        payload.title ||= I18n.t(EXCEPTION_CODE, scope: 'fun_with_json_api.exceptions')
        payload.status ||= '409'
        payload.pointer ||= '/data/id'
        super
      end
    end
  end
end
