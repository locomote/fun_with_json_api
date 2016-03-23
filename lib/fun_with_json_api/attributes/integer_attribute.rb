module FunWithJsonApi
  module Attributes
    class IntegerAttribute < FunWithJsonApi::Attribute
      def call(value)
        Integer(value.to_s) if value
      rescue ArgumentError => exception
        raise build_invalid_attribute_error(exception)
      end

      private

      def build_invalid_attribute_error(exception)
        payload = ExceptionPayload.new
        payload.detail = I18n.t('fun_with_json_api.exceptions.invalid_integer_attribute')
        payload.pointer = "/data/attributes/#{name}"
        Exceptions::InvalidAttribute.new(exception.message, payload)
      end
    end
  end
end
