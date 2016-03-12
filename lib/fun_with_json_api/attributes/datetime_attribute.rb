module FunWithJsonApi
  module Attributes
    class DatetimeAttribute < Attribute
      def call(value)
        DateTime.iso8601(value) if value
      end
    end
  end
end
