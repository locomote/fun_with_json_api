module FunWithJsonApi
  module Exceptions
    class RelationshipMethodNotSupported < FunWithJsonApi::Exception
      EXCEPTION_CODE = 'collection_method_not_supported'.freeze

      def initialize(message, payload = ExceptionPayload.new)
        payload = Array.wrap(payload).each do |unsupported|
          unsupported.code ||= EXCEPTION_CODE
          unsupported.title ||= I18n.t(EXCEPTION_CODE, scope: 'fun_with_json_api.exceptions')
          unsupported.status ||= '403'
        end
        super
      end
    end
  end
end
