module FunWithJsonApi
  module Exceptions
    # Indicates a Resource or Collection item not authorized
    class UnauthorisedResource < FunWithJsonApi::Exception
      def initialize(message, payload = ExceptionPayload.new)
        payload = Array.wrap(payload).each do |unauthorized|
          unauthorized.code ||= 'unauthorized_resource'
          unauthorized.title ||=
            I18n.t('unauthorized_resource', scope: 'fun_with_json_api.exceptions')
          unauthorized.status ||= '403'
        end
        super
      end
    end
  end
end
