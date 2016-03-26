module FunWithJsonApi
  module Exceptions
    # A server MUST return 409 Conflict when processing a PATCH request in which the resource
    # object's type and id do not match the server's endpoint
    class InvalidDocumentIdentifier < FunWithJsonApi::Exception
      EXCEPTION_CODE = 'invalid_document_identifier'.freeze

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
