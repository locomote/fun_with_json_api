module FunWithJsonApi
  module Exceptions
    # Indicates a Supplied relationships value is not able to be found
    class MissingRelationship < FunWithJsonApi::Exception
      def initialize(message, payload = ExceptionPayload.new)
        payload.code ||= 'missing_relationship'
        payload.title ||= I18n.t(:missing_relationship, scope: 'fun_with_json_api.exceptions')
        payload.status ||= '404'
        super
      end
    end
  end
end
