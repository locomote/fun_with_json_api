require 'fun_with_json_api/exception'

module FunWithJsonApi
  class SchemaValidator
    def self.check(api_document, deserializer, resource)
      new(api_document, deserializer, resource).check
    end

    private_class_method :new

    attr_reader :api_document
    attr_reader :deserializer
    attr_reader :resource

    def initialize(api_document, deserializer, resource)
      @api_document = api_document.deep_stringify_keys
      @deserializer = deserializer
      @resource = resource
    end

    def check
      FunWithJsonApi::SchemaValidators::CheckDocumentTypeMatchesResource.call(self)
      FunWithJsonApi::SchemaValidators::CheckDocumentIdMatchesResource.call(self)
    end

    def document_id
      @document_id ||= api_document['data']['id']
    end

    def document_type
      @document_type ||= api_document['data']['type']
    end

    def resource_id
      @resource_id ||= resource.send(deserializer.id_param).to_s
    end

    def resource_type
      @resource_type ||= deserializer.type
    end
  end
end

# Load known Schema Validators
Dir["#{File.dirname(__FILE__)}/schema_validators/**/*.rb"].each { |f| require f }
