require 'fun_with_json_api/exception'

module FunWithJsonApi
  # Abstract Handles updating a collection relationship.
  # Override the `insert`, `remove` and `replace` methods, or provide a block that perfoms the
  # desired action on the collection.
  class CollectionManager
    attr_reader :parent_resource
    attr_reader :deserializer

    def initialize(parent_resource, deserializer_class, deserializer_options)
      @parent_resource = parent_resource
      @deserializer = deserializer_class.create(deserializer_options)
    end

    # Loads a collection from the document
    # Use this method when implementinog a CollectionManager
    def load_collection(document)
      FunWithJsonApi::FindCollectionFromDocument.find(document, deserializer)
    end

    # Inserts all records from a document into the parent resource
    # Either provide a block method that adds an individual item or override this method
    #
    # The block will be provided with a resource and must return true,
    # or an exception with a payload will be raised after all items have been iterated through
    #
    # You need to reverse all changes made in the event of an exception,
    # wrapping an an ActiveRecord::Base.transaction block will usually work
    def insert_records(document, failure_message_or_callable = nil, &block)
      # Action is not supported unless overridden, or a block is defined
      unless block_given?
        raise build_relationship_not_supported_exception(
          "Override #{self.class.name}#insert_records or supply a block",
          insert_not_supported_message
        )
      end
      update_collection_items(load_collection(document), failure_message_or_callable, &block)
    end

    # Removes all records from a document from the parent resource
    # Either provide a block method that removes an individual item or override this method
    #
    # The block will be provided with a resource and must return true,
    # or an exception with a payload will be raised after all items have been iterated through
    #
    # You need to reverse all changes made in the event of an exception,
    # wrapping an an ActiveRecord::Base.transaction block will usually work
    def remove_records(document, failure_message_or_callable = nil, &block)
      # Action is not supported unless overridden, or a block is defined
      unless block_given?
        raise build_relationship_not_supported_exception(
          "Override #{self.class.name}#remove_records or supply a block",
          remove_not_supported_message
        )
      end
      update_collection_items(load_collection(document), failure_message_or_callable, &block)
    end

    def replace_all_records(_document)
      # Action is not supported unless overridden
      raise build_relationship_not_supported_exception(
        "Override #{self.class.name}#replace_all_records to implement replace all",
        replace_all_not_supported_message
      )
    end

    def failure_message_for_resource(resource, failure_message_or_callable)
      resource_id = deserializer.format_resource_id(resource)
      failure_message = failure_message_or_callable
      if failure_message.respond_to?(:call)
        failure_message = failure_message.call(resource_id)
      end
      failure_message || default_invalid_resource_message(resource_id)
    end

    protected

    def insert_not_supported_message
      I18n.t(
        'insert_not_supported',
        resource: deserializer.type,
        scope: 'fun_with_json_api.collection_manager'
      )
    end

    def remove_not_supported_message
      I18n.t(
        'remove_not_supported',
        resource: deserializer.type,
        scope: 'fun_with_json_api.collection_manager'
      )
    end

    def replace_all_not_supported_message
      I18n.t(
        'replace_all_not_supported',
        resource: deserializer.type,
        scope: 'fun_with_json_api.collection_manager'
      )
    end

    def default_invalid_resource_message(resource_id)
      I18n.t(
        'invalid_resource',
        resource: deserializer.type,
        resource_id: resource_id,
        scope: 'fun_with_json_api.collection_manager'
      )
    end

    def update_collection_items(collection, failure_message_or_callable = nil)
      failed_resources_hash = {}
      collection.each_with_index.map do |resource, index|
        failed_resources_hash[index] = resource unless yield(resource)
      end.reject(&:nil?)
      if failed_resources_hash.any?
        raise_invalid_resource_exception(failed_resources_hash, failure_message_or_callable)
      end
    end

    private

    def build_relationship_not_supported_exception(debug_message, exception_message)
      Exceptions::RelationshipMethodNotSupported.new(
        debug_message, ExceptionPayload.new(detail: exception_message)
      )
    end

    def raise_invalid_resource_exception(failed_resources_hash, failure_message_or_callable)
      raise Exceptions::InvalidResource.new(
        'Unable to update relationship due to errors with collection',
        build_invalid_resource_exception_payload(failed_resources_hash, failure_message_or_callable)
      )
    end

    def build_invalid_resource_exception_payload(failed_resources_hash, failure_message_or_callable)
      failed_resources_hash.map do |index, resource|
        failure_message = failure_message_for_resource(resource, failure_message_or_callable)
        ExceptionPayload.new(detail: failure_message, pointer: "/data/#{index}/id")
      end
    end
  end
end
