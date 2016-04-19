module FunWithJsonApi
  module Exceptions
    # Indicates a supplied attribute value is known but unable to be changed by this endpoint
    class UnauthorizedAttribute < FunWithJsonApi::Exception
      def initialize(message, payload = ExceptionPayload.new)
        payload = Array.wrap(payload).each do |unknown|
          unknown.code ||= 'unauthorized_attribute'
          unknown.title ||= I18n.t(
            :unauthorized_attribute, scope: 'fun_with_json_api.exceptions'
          )
          unknown.status ||= '403'
        end
        super
      end
    end
  end
end
