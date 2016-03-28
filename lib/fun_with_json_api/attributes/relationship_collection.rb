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
        @deserializer_options = options

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
          raise build_invalid_relationship_collection_error(values)
        end

        collection = deserializer.load_collection_from_id_values(values)

        # Ensure the collection size matches
        expected_size = values.size
        result_size = collection.size
        if result_size != expected_size
          raise build_missing_relationship_error_from_collection(collection, values)
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
          @deserializer_options.merge(
            attributes: [],
            relationships: []
          )
        )
      end

      def build_invalid_relationship_collection_error(values)
        exception_message = "#{name} relationship should contain a array of '#{type}' data"
        payload = ExceptionPayload.new
        payload.pointer = "/data/relationships/#{name}"
        payload.detail = exception_message
        Exceptions::InvalidRelationship.new(exception_message + ": #{values.inspect}", payload)
      end

      def build_missing_relationship_error_from_collection(collection, values)
        collection_ids = deserializer.format_collection_ids(collection)

        payload = values.each_with_index.map do |resource_id, index|
          next if collection_ids.include?(resource_id)
          build_missing_relationship_payload(resource_id, index)
        end.reject(&:nil?)

        missing_values = values.reject { |value| collection_ids.include?(value.to_s) }
        exception_message = "Couldn't find #{resource_class} items with "\
                            "#{id_param} in #{missing_values.inspect}"
        Exceptions::MissingRelationship.new(exception_message, payload)
      end

      def build_missing_relationship_payload(resource_id, index)
        ExceptionPayload.new.tap do |payload|
          payload.pointer = "/data/relationships/#{name}/#{index}/id"
          payload.detail = "Unable to find '#{type}' with matching id: \"#{resource_id}\""
        end
      end
    end
  end
end
