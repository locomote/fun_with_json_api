require 'fun_with_json_api/exception'

module FunWithJsonApi
  # Abstract Handles updating a collection relationship.
  # Override the `insert`, `remove` and `replace` methods, and make use of `parent_resource`
  # `load_collection` and `report_invalid_resources_at_index!` to load and update a relationship
  # collection.
  class CollectionManager
    attr_reader :parent_resource
    attr_reader :deserializer_class
    attr_reader :deserializer_options

    def initialize(parent_resource, deserializer_class, deserializer_options)
      @parent_resource = parent_resource
      @deserializer_class = deserializer_class
      @deserializer_options = deserializer_options
    end

    # Loads a collection from the document
    # Use this method when implementinog a CollectionManager
    def load_collection(document)
      FunWithJsonApi.find_collection(document, deserializer_class, deserializer_options)
    end

    def insert_records(_document)
      # Action is not supported unless overridden
      raise build_relationship_not_supported_exception(
        "Override #{self.class.name}#insert_records to implement insert",
        insert_not_supported_message
      )
    end

    def remove_records(_document)
      # Action is not supported unless overridden
      raise build_relationship_not_supported_exception(
        "Override #{self.class.name}#remove_records to implement remove",
        remove_not_supported_message
      )
    end

    def replace_all_records(_document)
      # Action is not supported unless overridden
      raise build_relationship_not_supported_exception(
        "Override #{self.class.name}#replace_all_records to implement replace all",
        replace_all_not_supported_message
      )
    end

    def report_invalid_resources_at_index!(resource_indexes, reason_message_or_callable = nil)
      raise build_invalid_resource_exception(resource_indexes, reason_message_or_callable)
    end

    protected

    def insert_not_supported_message
      I18n.t(
        'insert_not_supported',
        resource: deserializer_class.type,
        scope: 'fun_with_json_api.collection_manager'
      )
    end

    def remove_not_supported_message
      I18n.t(
        'remove_not_supported',
        resource: deserializer_class.type,
        scope: 'fun_with_json_api.collection_manager'
      )
    end

    def replace_all_not_supported_message
      I18n.t(
        'replace_all_not_supported',
        resource: deserializer_class.type,
        scope: 'fun_with_json_api.collection_manager'
      )
    end

    def default_invalid_resource_message
      I18n.t(
        'invalid_resource',
        resource: deserializer_class.type,
        scope: 'fun_with_json_api.collection_manager'
      )
    end

    private

    def build_relationship_not_supported_exception(debug_message, exception_message)
      Exceptions::RelationshipMethodNotSupported.new(
        debug_message, ExceptionPayload.new(detail: exception_message)
      )
    end

    def build_invalid_resource_exception(resource_index_or_indexes, reason_message_or_callable)
      resource_indexes = Array.wrap(resource_index_or_indexes)
      Exceptions::InvalidResource.new(
        'Unable to update relationship due to errors with collection',
        build_invalid_resource_exception_payload(resource_indexes, reason_message_or_callable)
      )
    end

    def build_invalid_resource_exception_payload(resource_indexes, reason_message_or_callable)
      resource_indexes.map do |index|
        reason_message = reason_message_or_callable
        reason_message = reason_message.call(index) if reason_message.respond_to?(:call)
        reason_message ||= default_invalid_resource_message

        ExceptionPayload.new(
          pointer: "/data/#{index}/id",
          detail: reason_message
        )
      end
    end
  end
end
