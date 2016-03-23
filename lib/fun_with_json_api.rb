require 'fun_with_json_api/exception'
require 'fun_with_json_api/attribute'

require 'fun_with_json_api/pre_deserializer'
require 'fun_with_json_api/deserializer'
require 'fun_with_json_api/deserializer_config_builder'

# Makes working with JSON:API fun!
module FunWithJsonApi
  module_function

  def deserialize(api_document, deserializer_class, options = {})
    # Prepare the deserializer and the expected config
    deserializer = deserializer_class.create(options)

    # Run through initial document structure validation and deserialization
    unfiltered = FunWithJsonApi::PreDeserializer.parse(api_document, deserializer)

    # Ensure document matches schema, and sanitize values
    deserializer.sanitize_params(unfiltered)
  end
end

require 'fun_with_json_api/railtie' if defined?(Rails)
