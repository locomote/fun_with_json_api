module FunWithJsonApi
  module Exceptions
    class InvalidDocument < FunWithJsonApi::Exception
      def initialize(message, payload = ExceptionPayload.new)
        payload.code ||= 'invalid_document'
        payload.title ||= I18n.t(:invalid_document, scope: 'fun_with_json_api.exceptions')
        payload.status ||= '400'
        super
      end
    end
  end
end
