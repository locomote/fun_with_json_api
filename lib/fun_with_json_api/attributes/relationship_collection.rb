module FunWithJsonApi
  module Attributes
    class RelationshipCollection < FunWithJsonApi::Attribute
      def self.create(name, deserializer_class_or_callable, options = {})
        new(name, deserializer_class_or_callable, options)
      end

      def initialize(name, deserializer_class, options = {})
        super(name, options.reverse_merge(as: name.to_s.singularize.to_sym))
        @deserializer_class = deserializer_class
        @deserializer_options = options.reverse_merge(
          attributes: [],
          relationships: []
        )

        check_as_attribute_is_singular!
      end

      # Expects an array of id values for a nested collection
      def call(values, deserializer)
        unless values.nil? || values.is_a?(Array)
          raise build_invalid_relationship_collection_error(deserializer, values)
        end

        collection = deserializer.load_collection_from_id_values(values)

        # Ensure the collection size matches
        expected_size = values.size
        result_size = collection.size
        if result_size != expected_size
          raise build_missing_relationship_error_from_collection(deserializer, collection, values)
        end

        # Call ActiceRecord#pluck if it is available
        convert_collection_to_ids(deserializer, collection)
      end

      # User the singular of `as` that is how AMS converts the value
      def param_value
        :"#{as}_ids"
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

      def check_as_attribute_is_singular!
        if as.to_s != as.to_s.singularize
          raise ArgumentError, "Use a singular relationship as value: {as: :#{as.to_s.singularize}}"
        end
      end

      def convert_collection_to_ids(deserializer, collection)
        if collection.respond_to? :pluck
          # Well... pluck+arel doesn't work with SQLite, but select at least is safe
          collection = collection.select(deserializer.resource_class.arel_table[:id])
        end
        collection.map(&:id)
      end

      def build_invalid_relationship_collection_error(deserializer, values)
        exception_message = "#{name} relationship should contain a array of"\
                            " '#{deserializer.type}' data"
        payload = ExceptionPayload.new
        payload.pointer = "/data/relationships/#{name}"
        payload.detail = exception_message
        Exceptions::InvalidRelationship.new(exception_message + ": #{values.inspect}", payload)
      end

      def build_missing_relationship_error_from_collection(deserializer, collection, values)
        collection_ids = deserializer.format_collection_ids(collection)

        payload = values.each_with_index.map do |resource_id, index|
          next if collection_ids.include?(resource_id)
          build_missing_relationship_payload(deserializer, resource_id, index)
        end.reject(&:nil?)

        missing_values = values.reject { |value| collection_ids.include?(value.to_s) }
        exception_message = "Couldn't find #{deserializer.resource_class} items with "\
                            "#{deserializer.id_param} in #{missing_values.inspect}"
        Exceptions::MissingRelationship.new(exception_message, payload)
      end

      def build_missing_relationship_payload(deserializer, resource_id, index)
        ExceptionPayload.new.tap do |payload|
          payload.pointer = "/data/relationships/#{name}/#{index}/id"
          payload.detail = "Unable to find '#{deserializer.type}' with matching id"\
                           ": \"#{resource_id}\""
        end
      end
    end
  end
end
