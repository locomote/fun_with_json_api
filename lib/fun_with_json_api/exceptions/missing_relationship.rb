module FunWithJsonApi
  module Exceptions
    # Indicates a Supplied relationships value is not able to be found
    class MissingRelationship < FunWithJsonApi::Exception
      def initialize(message, payload = ExceptionPayload.new)
        payload = Array.wrap(payload).each do |missing|
          missing.code ||= 'missing_relationship'
          missing.title ||= I18n.t(:missing_relationship, scope: 'fun_with_json_api.exceptions')
          missing.status ||= '404'
        end
        super
      end
    end
  end
end
