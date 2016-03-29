module FunWithJsonApi
  class FindCollectionFromDocument
    def self.find(*args)
      new(*args).find
    end

    private_class_method :new

    attr_reader :document
    attr_reader :deserializer
    delegate :id_param, :id_param, :resource_class, to: :deserializer

    def initialize(document, deserializer)
      @document = FunWithJsonApi.sanitize_document(document)
      @deserializer = deserializer
    end

    def find
      raise build_invalid_document_error unless document_is_valid_collection?

      # Skip the checks, no point running through them for an empty array
      return [] if document_ids.empty?

      # Ensure the document matches the expected resource
      check_document_types_match_deserializer!

      # Load resource from id value
      deserializer.load_collection_from_id_values(document_ids).tap do |collection|
        check_collection_contains_all_requested_resources!(collection)
      end
    end

    def document_ids
      @document_id ||= document['data'].map { |item| item['id'] }
    end

    def document_types
      @document_type ||= document['data'].map { |item| item['type'] }.uniq
    end

    def resource_type
      @resource_type ||= deserializer.type
    end

    def document_is_valid_collection?
      document.key?('data') && document['data'].is_a?(Array)
    end

    private

    def check_collection_contains_all_requested_resources!(collection)
      if collection.size != document_ids.size
        collection_ids = deserializer.format_collection_ids(collection)
        raise build_missing_resources_error(collection_ids)
      end
    end

    def check_document_types_match_deserializer!
      invalid_document_types = document_types.reject { |type| type == resource_type }
      raise build_invalid_document_types_error if invalid_document_types.any?
    end

    def build_invalid_document_error
      payload = ExceptionPayload.new
      payload.pointer = '/data'
      payload.detail = 'Expected data to be an Array of resources'
      Exceptions::InvalidDocument.new(
        "Expected root data element with an Array: #{document.inspect}",
        payload
      )
    end

    def build_invalid_document_types_error
      message = 'Expected type for each item to match expected resource type'\
                ": '#{resource_type}'"
      payload = document['data'].each_with_index.map do |data, index|
        next if data['type'] == resource_type
        ExceptionPayload.new(
          pointer: "/data/#{index}/type",
          detail: document_type_does_not_match_endpoint_message(data['type'])
        )
      end.reject(&:nil?)
      Exceptions::InvalidDocumentType.new(message, payload)
    end

    def build_missing_resources_error(collection_ids)
      payload = document_ids.each_with_index.map do |resource_id, index|
        build_missing_resource_payload(collection_ids, resource_id, index)
      end.reject(&:nil?)

      missing_values = document_ids.reject { |value| collection_ids.include?(value.to_s) }
      message = "Couldn't find #{resource_class} items with "\
                "#{id_param} in #{missing_values.inspect}"
      Exceptions::MissingResource.new(message, payload)
    end

    def build_missing_resource_payload(collection_ids, resource_id, index)
      unless collection_ids.include?(resource_id)
        ExceptionPayload.new(
          pointer: "/data/#{index}/id",
          detail: missing_resource_message(resource_id)
        )
      end
    end

    def document_type_does_not_match_endpoint_message(type)
      I18n.t(
        :invalid_document_type,
        type: type,
        resource: resource_type,
        scope: 'fun_with_json_api.find_collection_from_document'
      )
    end

    def missing_resource_message(resource_id)
      I18n.t(
        :missing_resource,
        resource: resource_type,
        resource_id: resource_id,
        scope: 'fun_with_json_api.find_collection_from_document'
      )
    end
  end
end
