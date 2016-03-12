module FunWithJsonApi
  module Attributes
    class StringAttribute < Attribute
      def call(value)
        value.to_s if value
      end
    end
  end
end
