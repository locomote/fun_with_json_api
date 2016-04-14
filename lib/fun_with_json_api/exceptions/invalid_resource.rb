require 'fun_with_json_api/exceptions/unauthorized_resource'

module FunWithJsonApi
  module Exceptions
    # Indicates a Resource was unable to be used with performing an update
    class InvalidResource < FunWithJsonApi::Exceptions::UnauthorizedResource
      def initialize(message, payload = ExceptionPayload.new)
        payload = Array.wrap(payload).each do |invalid|
          invalid.title ||= I18n.t('invalid_resource', scope: 'fun_with_json_api.exceptions')
        end
        super
      end
    end
  end
end
