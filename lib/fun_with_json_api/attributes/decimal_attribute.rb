module FunWithJsonApi
  module Attributes
    class DecimalAttribute < Attribute
      def call(value)
        BigDecimal.new(value) if value
      end
    end
  end
end
