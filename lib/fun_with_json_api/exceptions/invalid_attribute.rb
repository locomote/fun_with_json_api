module FunWithJsonApi
  module Exceptions
    # Indicates a Supplied attributes value is not formatted correctly
    class InvalidAttribute < FunWithJsonApi::Exception
      def initialize(message, payload = ExceptionPayload.new)
        payload.code ||= 'invalid_attribute'
        payload.title ||= I18n.t(:invalid_attribute, scope: 'fun_with_json_api.exceptions')
        payload.status ||= '400'
        super
      end
    end
  end
end
