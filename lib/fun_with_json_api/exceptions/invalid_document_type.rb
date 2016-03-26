module FunWithJsonApi
  module Exceptions
    # A server MUST return 409 Conflict when processing a POST request in which the resource
    # object's type is not among the type(s) that constitute the collection represented by the
    # endpoint.
    class InvalidDocumentType < FunWithJsonApi::Exception
      EXCEPTION_CODE = 'invalid_document_type'.freeze

      def initialize(message, payload = ExceptionPayload.new)
        payload.code ||= EXCEPTION_CODE
        payload.title ||= I18n.t(EXCEPTION_CODE, scope: 'fun_with_json_api.exceptions')
        payload.status ||= '409'
        payload.pointer ||= '/data/type'
        super
      end
    end
  end
end
