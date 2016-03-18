module FunWithJsonApi
  module Attributes
    class Relationship < FunWithJsonApi::Attribute
      # Creates a new Relationship with name
      # @param name [String] name of the relationship
      # @param deserializer_class_or_callable [Class] Class of Deserializer or
      #   a callable that returns one
      # @param options[at] [String] alias value for the attribute
      def self.create(name, deserializer_class_or_callable, options = {})
        new(name, deserializer_class_or_callable, options)
      end

      delegate :id_param,
               :type,
               :resource_class,
               to: :deserializer

      def initialize(name, deserializer_class, options = {})
        super(name, options)
        @deserializer_class = deserializer_class
      end

      def deserializer
        @deserializer ||= create_deserializer_from_deserializer_class
      end

      def call(id_value)
        unless id_value.nil? || !id_value.is_a?(Array)
          raise StandardError, "should be a single '#{type} resource!"
        end

        resource_class.find_by!(id_param => id_value).try(:id) if id_value
      end

      def param_value
        :"#{as}_id"
      end

      private

      # Creates a new Deserializer from the deserializer class
      def create_deserializer_from_deserializer_class
        if @deserializer_class.respond_to?(:call)
          @deserializer_class.call
        else
          @deserializer_class
        end.create(
          attributes: [],
          relationships: []
        )
      end
    end
  end
end
