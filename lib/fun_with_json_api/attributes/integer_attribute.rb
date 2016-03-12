module FunWithJsonApi
  module Attributes
    class IntegerAttribute < FunWithJsonApi::Attribute
      def call(value)
        Integer(value) if value
      end
    end
  end
end
