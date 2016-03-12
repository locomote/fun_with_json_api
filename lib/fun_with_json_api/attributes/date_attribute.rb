module FunWithJsonApi
  module Attributes
    class DateAttribute < Attribute
      DATE_FORMAT = '%Y-%m-%d'.freeze

      def call(value)
        Date.strptime(value, DATE_FORMAT) if value
      end
    end
  end
end
