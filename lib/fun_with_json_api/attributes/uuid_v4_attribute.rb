module FunWithJsonApi
  module Attributes
    # Attribute that only accepts a properly generated and formatted UUID version 4
    # as described in RFC 4122
    class UuidV4Attribute < Attribute
      # http://blog.arkency.com/2014/10/how-to-start-using-uuid-in-activerecord-with-postgresql/
      UUID_V4_REGEX = /\A[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12}\z/

      def decode(value)
        return value if value.nil? || value =~ UUID_V4_REGEX

        raise build_invalid_attribute_error(value)
      end

      private

      def build_invalid_attribute_error(value)
        payload = ExceptionPayload.new
        payload.detail = I18n.t('fun_with_json_api.exceptions.invalid_uuid_v4_attribute')
        payload.pointer = "/data/attributes/#{name}"
        Exceptions::InvalidAttribute.new(
          "Value is not a RFC 4122 Version 4 UUID: #{value.class.name}", payload
        )
      end
    end
  end
end
