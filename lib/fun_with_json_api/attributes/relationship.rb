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

      def initialize(name, deserializer_class, options = {})
        super(name, options)
        @deserializer_class = deserializer_class
        @deserializer_options = options.reverse_merge(
          attributes: [],
          relationships: []
        )
      end

      def call(id_value, deserializer)
        unless id_value.nil? || !id_value.is_a?(Array)
          raise build_invalid_relationship_error(deserializer, id_value)
        end

        resource = deserializer.load_resource_from_id_value(id_value)
        return resource.id if resource

        raise build_missing_relationship_error(deserializer, id_value)
      end

      def param_value
        :"#{as}_id"
      end

      def create_deserializer_with_options(options)
        if @deserializer_class.respond_to?(:call)
          @deserializer_class.call
        else
          @deserializer_class
        end.create(
          options.reverse_merge(@deserializer_options)
        )
      end

      private

      def build_invalid_relationship_error(deserializer, id_value)
        exception_message = "#{name} relationship should contain a single '#{deserializer.type}'"\
                            ' data hash'
        payload = ExceptionPayload.new
        payload.pointer = "/data/relationships/#{name}"
        payload.detail = exception_message
        Exceptions::InvalidRelationship.new(exception_message + ": #{id_value.inspect}", payload)
      end

      def build_missing_relationship_error(deserializer, id_value, message = nil)
        message ||= missing_resource_debug_message(deserializer, id_value)
        payload = ExceptionPayload.new
        payload.pointer = "/data/relationships/#{name}/id"
        payload.detail = "Unable to find '#{deserializer.type}' with matching id"\
                         ": #{id_value.inspect}"
        Exceptions::MissingRelationship.new(message, payload)
      end

      def missing_resource_debug_message(deserializer, id_value)
        "Couldn't find #{deserializer.resource_class.name}"\
        " where #{deserializer.id_param} = #{id_value.inspect}"
      end
    end
  end
end
