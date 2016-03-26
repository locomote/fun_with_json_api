module FunWithJsonApi
  module Exceptions
    # A server MUST return 403 Forbidden in response to an unsupported request to create a resource
    # with a client-generated ID.
    class IllegalClientGeneratedIdentifier < FunWithJsonApi::Exception
      EXCEPTION_CODE = 'illegal_client_generated_identifier'.freeze

      def initialize(message, payload = ExceptionPayload.new)
        payload.code ||= EXCEPTION_CODE
        payload.title ||= I18n.t(EXCEPTION_CODE, scope: 'fun_with_json_api.exceptions')
        payload.status ||= '403'
        payload.pointer ||= '/data/id'
        super
      end
    end
  end
end
