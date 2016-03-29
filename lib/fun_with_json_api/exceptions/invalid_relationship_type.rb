module FunWithJsonApi
  module Exceptions
    # Indicates a supplied relationships type does match expected values
    class InvalidRelationshipType < FunWithJsonApi::Exception
      ERROR_CODE = 'invalid_relationship_type'.freeze

      def initialize(message, payload = ExceptionPayload.new)
        Array.wrap(payload).each do |invalid|
          invalid.code ||= ERROR_CODE
          invalid.title ||= I18n.t(ERROR_CODE, scope: 'fun_with_json_api.exceptions')
          invalid.status ||= '409'
        end
        super
      end
    end
  end
end
