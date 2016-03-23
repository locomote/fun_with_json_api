module FunWithJsonApi
  module Attributes
    class RelationshipCollection < FunWithJsonApi::Attribute
      def self.create(name, deserializer_class_or_callable, options = {})
        new(name, deserializer_class_or_callable, options)
      end

      delegate :id_param,
               :type,
               :resource_class,
               to: :deserializer

      def initialize(name, deserializer_class, options = {})
        super(name, options.reverse_merge(as: name.to_s.singularize.to_sym))
        @deserializer_class = deserializer_class

        if as.to_s != as.to_s.singularize
          raise ArgumentError, "Use a singular relationship as value: {as: :#{as.to_s.singularize}}"
        end
      end

      def deserializer
        @deserializer ||= create_deserializer_from_deserializer_class
      end

      # Expects an array of id values for a nested collection
      def call(values)
        unless values.nil? || values.is_a?(Array)
          raise StandardError, "should be an array of #{type} resources!"
        end

        collection = resource_class.where(id_param => values)

        # Ensure the collection size matches
        expected_size = values.size
        result_size = collection.size
        if result_size != expected_size
          raise StandardError, "Expected #{expected_size} values, received #{result_size} items"
        end

        # Call ActiceRecord#pluck if it is available
        convert_collection_to_ids(collection)
      end

      # User the singular of `as` that is how AMS converts the value
      def param_value
        :"#{as}_ids"
      end

      private

      def convert_collection_to_ids(collection)
        if collection.respond_to? :pluck
          # Well... pluck+arel doesn't work with SQLite, but select at least is safe
          collection = collection.select(resource_class.arel_table[:id])
        end
        collection.map(&:id)
      end

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
