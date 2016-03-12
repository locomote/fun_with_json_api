module FunWithJsonApi
  module Attributes
    class FloatAttribute < FunWithJsonApi::Attribute
      def call(value)
        Float(value) if value
      end
    end
  end
end
