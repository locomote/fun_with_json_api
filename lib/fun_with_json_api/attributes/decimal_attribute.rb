module FunWithJsonApi
  module Attributes
    class DecimalAttribute < Attribute
      def decode(value)
        if value
          unless value.to_s =~ /[0-9]+(\.[0-9]+)?/
            raise build_invalid_attribute_error(value)
          end
          BigDecimal(value.to_s)
        end
      end

      protected

      def build_invalid_attribute_error(value)
        payload = ExceptionPayload.new
        payload.detail = I18n.t('fun_with_json_api.exceptions.invalid_decimal_attribute')
        payload.pointer = "/data/attributes/#{name}"
        Exceptions::InvalidAttribute.new("Unable to parse decimal: #{value.inspect}", payload)
      end
    end
  end
end
