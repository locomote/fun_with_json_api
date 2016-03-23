module FunWithJsonApi
  module Exceptions
    # Indicates a Supplied relationships value is not formatted correctly
    class InvalidRelationship < FunWithJsonApi::Exception
      def initialize(message, payload = ExceptionPayload.new)
        payload.code ||= 'invalid_relationship'
        payload.title ||= I18n.t(:invalid_relationship, scope: 'fun_with_json_api.exceptions')
        payload.status ||= '400'
        super
      end
    end
  end
end
