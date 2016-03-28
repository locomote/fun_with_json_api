require 'fun_with_json_api/exception'
require 'fun_with_json_api/attribute'

require 'fun_with_json_api/pre_deserializer'
require 'fun_with_json_api/deserializer'
require 'fun_with_json_api/schema_validator'
require 'fun_with_json_api/find_resource_from_document'

# Makes working with JSON:API fun!
module FunWithJsonApi
  MEDIA_TYPE = 'application/vnd.api+json'.freeze

  module_function

  def deserialize(api_document, deserializer_class, resource = nil, options = {})
    # Prepare the deserializer and the expected config
    deserializer = deserializer_class.create(options)

    # Run through initial document structure validation and deserialization
    unfiltered = FunWithJsonApi::PreDeserializer.parse(api_document, deserializer)

    # Check the document matches up with expected resource parameters
    FunWithJsonApi::SchemaValidator.check(api_document, deserializer, resource)

    # Ensure document matches schema, and sanitize values
    deserializer.sanitize_params(unfiltered)
  end

  def deserialize_resource(api_document, deserializer_class, resource, options = {})
    raise ArgumentError, 'resource cannot be nil' if resource.nil?
    deserialize(api_document, deserializer_class, resource, options)
  end

  def find_resource(api_document, deserializer_class)
    # Prepare the deserializer for loading a resource
    deserializer = deserializer_class.create(attributes: [], relationships: [])

    # Load the resource from the document id
    FunWithJsonApi::FindResourceFromDocument.find(api_document, deserializer)
  end
end

require 'fun_with_json_api/railtie' if defined?(Rails)
