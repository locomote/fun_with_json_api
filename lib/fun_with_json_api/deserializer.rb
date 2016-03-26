require 'active_support/inflector'
require 'fun_with_json_api/attribute'
require 'fun_with_json_api/deserializer_class_methods'

module FunWithJsonApi
  class Deserializer
    extend FunWithJsonApi::DeserializerClassMethods

    # Creates a new instance of a
    def self.create(options = {})
      new(options)
    end

    # Use DeserializerClass.create to build new instances
    private_class_method :new

    attr_reader :id_param
    attr_reader :type
    attr_reader :resource_class

    attr_reader :attributes
    attr_reader :relationships

    def initialize(options = {})
      @id_param = options.fetch(:id_param) { self.class.id_param }
      @type = options[:type]
      @resource_class = options[:resource_class]
      @attributes = filter_attributes_by_name(options[:attributes], self.class.attributes)
      @relationships = filter_attributes_by_name(options[:relationships], self.class.relationships)
    end

    # Loads a collection of of `resource_class` instances with `id_param` matching `id_values`
    def load_collection_from_id_param(id_values)
      resource_class.where(id_param => id_values)
    end

    # Loads a single instance of `resource_class` with a `id_param` matching `id_value`
    def load_resource_from_id_param(id_value)
      resource_class.find_by!(id_param => id_value)
    end

    # Takes a parsed params hash from ActiveModelSerializers::Deserialization and sanitizes values
    def sanitize_params(params)
      Hash[
        serialize_attribute_values(attributes, params) +
        serialize_attribute_values(relationships, params)
      ]
    end

    def type
      @type ||= self.class.type
    end

    def resource_class
      @resource_class ||= self.class.resource_class
    end

    private

    def filter_attributes_by_name(attribute_names, attributes)
      if attribute_names
        attributes.keep_if { |attribute| attribute_names.include?(attribute.name) }
      else
        attributes
      end
    end

    # Calls <attribute.as> on the current instance, override the #<as> method to change loading
    def serialize_attribute_values(attributes, params)
      attributes.select { |attribute| params.key?(attribute.param_value) }
                .map { |attribute| serialize_attribute(attribute, params) }
    end

    # Calls <attribute.as> on the current instance, override the #<as> method to change loading
    def serialize_attribute(attribute, params)
      raw_value = params.fetch(attribute.param_value)
      [attribute.param_value, public_send(attribute.sanitize_attribute_method, raw_value)]
    end
  end
end
