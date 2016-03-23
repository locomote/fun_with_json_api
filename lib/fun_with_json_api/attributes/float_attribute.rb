module FunWithJsonApi
  module Attributes
    class FloatAttribute < FunWithJsonApi::Attribute
      def call(value)
        Float(value.to_s) if value
      rescue ArgumentError => exception
        raise build_invalid_attribute_error(exception, value)
      end

      private

      def build_invalid_attribute_error(exception, value)
        payload = ExceptionPayload.new
        payload.detail = I18n.t('fun_with_json_api.exceptions.invalid_float_attribute')
        payload.pointer = "/data/attributes/#{name}"
        Exceptions::InvalidAttribute.new(exception.message + ": #{value.inspect}", payload)
      end
    end
  end
end
