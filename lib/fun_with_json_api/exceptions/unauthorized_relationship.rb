module FunWithJsonApi
  module Exceptions
    # Indicates a supplied relationship value is unknown to the current deserializer
    class UnauthorizedRelationship < FunWithJsonApi::Exception
      def initialize(message, payload = ExceptionPayload.new)
        payload = Array.wrap(payload).each do |unknown|
          unknown.code ||= 'unauthorized_relationship'
          unknown.title ||= I18n.t(
            :unauthorized_relationship, scope: 'fun_with_json_api.exceptions'
          )
          unknown.status ||= '403'
        end
        super
      end
    end
  end
end
