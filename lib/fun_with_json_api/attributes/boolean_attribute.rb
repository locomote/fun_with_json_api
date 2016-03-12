module FunWithJsonApi
  module Attributes
    # Ensures a value is either Boolean.TRUE, Boolean.FALSE or nil
    # Raises an argument error otherwise
    class BooleanAttribute < Attribute
      def call(value)
        return nil if value.nil?
        return value if value.is_a?(TrueClass) || value.is_a?(FalseClass)

        raise ArgumentError, "#{value.inspect} should only be boolean true, false, or null"
      end
    end
  end
end
