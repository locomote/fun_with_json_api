module FunWithJsonApi
  module Exceptions
    # Indicates a Resource was unable to be used with performing an update
    class InvalidResource < FunWithJsonApi::Exception
      def initialize(message, payload = ExceptionPayload.new)
        payload = Array.wrap(payload).each do |invalid|
          invalid.code ||= 'invalid_resource'
          invalid.title ||= I18n.t('invalid_resource', scope: 'fun_with_json_api.exceptions')
          invalid.status ||= '422'
        end
        super
      end
    end
  end
end
