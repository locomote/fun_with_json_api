require 'active_model_serializers'

require 'fun_with_json_api/attribute'
require 'fun_with_json_api/deserializer'
require 'fun_with_json_api/deserializer_config_builder'

# Makes working with JSON:API fun!
module FunWithJsonApi
  module_function

  def deserialize(api_document, deserializer_class, options = {})
    # Prepare the deserializer and the expected config
    deserializer = deserializer_class.create(options)
    deserializer_config = FunWithJsonAPi::DeserializerConfigBuilder.build(deserializer)

    # Run through initial document structure validation and deserialization
    unfiltered = ActiveModelSerializers::Deserialization.jsonapi_parse!(
      api_document.to_h.deep_dup.deep_stringify_keys, deserializer_config
    )

    # Ensure document matches schema, and sanitize values
    deserializer.sanitize_params(unfiltered)
  end
end
