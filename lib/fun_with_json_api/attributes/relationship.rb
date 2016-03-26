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
          raise build_invalid_relationship_error(id_value)
        end

        resource = deserializer.load_resource_from_id_param(id_value)
        return resource.id if resource

        raise build_missing_relationship_error(id_value)
      rescue ActiveRecord::RecordNotFound => exception
        raise convert_record_not_found_error(exception, id_value)
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

      def build_invalid_relationship_error(id_value)
        exception_message = "#{name} relationship should contain a single '#{type}' data hash"
        payload = ExceptionPayload.new
        payload.pointer = "/data/relationships/#{name}"
        payload.detail = exception_message
        Exceptions::InvalidRelationship.new(exception_message + ": #{id_value.inspect}", payload)
      end

      def build_missing_relationship_error(id_value, message = nil)
        message ||= missing_resource_debug_message(id_value)
        payload = ExceptionPayload.new
        payload.pointer = "/data/relationships/#{name}/id"
        payload.detail = "Unable to find '#{type}' with matching id: #{id_value.inspect}"
        Exceptions::MissingRelationship.new(message, payload)
      end

      def convert_record_not_found_error(exception, id_value)
        exception_message = "#{missing_resource_debug_message(id_value)}: #{exception.message}"
        build_missing_relationship_error(id_value, exception_message)
      end

      def missing_resource_debug_message(id_value)
        "Couldn't find #{resource_class.name} where #{id_param} = #{id_value.inspect}"
      end
    end
  end
end
