module FunWithJsonApi
  module Exceptions
    # Indicates a Supplied relationships value is not formatted correctly
    class InvalidRelationship < FunWithJsonApi::Exception
      def initialize(message, payload = ExceptionPayload.new)
        Array.wrap(payload).each do |invalid|
          invalid.code ||= 'invalid_relationship'
          invalid.title ||= I18n.t(:invalid_relationship, scope: 'fun_with_json_api.exceptions')
          invalid.status ||= '400'
        end
        super
      end
    end
  end
end
