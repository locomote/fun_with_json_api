module FunWithJsonApi
  module Attributes
    # Ensures a value is either Boolean.TRUE, Boolean.FALSE or nil
    # Raises an argument error otherwise
    class BooleanAttribute < Attribute
      def decode(value)
        return nil if value.nil?
        return value if value.is_a?(TrueClass) || value.is_a?(FalseClass)

        raise build_invalid_attribute_error(value)
      end

      private

      def build_invalid_attribute_error(value)
        exception_message = I18n.t('fun_with_json_api.exceptions.invalid_boolean_attribute')
        payload = ExceptionPayload.new
        payload.detail = exception_message
        payload.pointer = "/data/attributes/#{name}"
        Exceptions::InvalidAttribute.new(exception_message + ": #{value.inspect}", payload)
      end
    end
  end
end
