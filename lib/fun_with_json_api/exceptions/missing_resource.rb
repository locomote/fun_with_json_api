module FunWithJsonApi
  module Exceptions
    # Indicates a Resource or Collection item was not able to be found
    class MissingResource < FunWithJsonApi::Exception
      def initialize(message, payload = ExceptionPayload.new)
        payload = Array.wrap(payload).each do |missing|
          missing.code ||= 'missing_resource'
          missing.title ||= I18n.t('missing_resource', scope: 'fun_with_json_api.exceptions')
          missing.status ||= '404'
        end
        super
      end
    end
  end
end
