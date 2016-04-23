module FunWithJsonApi
  module Attributes
    class DatetimeAttribute < Attribute
      def decode(value)
        DateTime.iso8601(value) if value
      rescue ArgumentError => exception
        raise build_invalid_attribute_error(exception, value)
      end

      private

      def build_invalid_attribute_error(exception, value)
        payload = ExceptionPayload.new
        payload.detail = I18n.t('fun_with_json_api.exceptions.invalid_datetime_attribute')
        payload.pointer = "/data/attributes/#{name}"
        Exceptions::InvalidAttribute.new(exception.message + ": #{value.inspect}", payload)
      end
    end
  end
end
