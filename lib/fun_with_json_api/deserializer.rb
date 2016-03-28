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
      @type = options.fetch(:type) { self.class.type }
      @resource_class = options[:resource_class]
      @resource_collection = options[:"#{type}_collection"] if @type
      load_attributes_from_options(options)
      load_relationships_from_options(options)
    end

    # Loads a collection of of `resource_class` instances with `id_param` matching `id_values`
    def load_collection_from_id_values(id_values)
      resource_collection.where(id_param => id_values)
    end

    def format_collection_ids(collection)
      collection.map { |resource| resource.public_send(id_param).to_s }
    end

    # Loads a single instance of `resource_class` with a `id_param` matching `id_value`
    def load_resource_from_id_value(id_value)
      resource_collection.find_by(id_param => id_value)
    end

    # Takes a parsed params hash from ActiveModelSerializers::Deserialization and sanitizes values
    def sanitize_params(params)
      Hash[
        serialize_attribute_values(attributes, params) +
        serialize_attribute_values(relationships, params)
      ]
    end

    def resource_class
      @resource_class ||= self.class.resource_class
    end

    def resource_collection
      @resource_collection ||= resource_class
    end

    private

    def load_attributes_from_options(options)
      @attributes = filter_attributes_by_name(options[:attributes], self.class.attributes)
    end

    def load_relationships_from_options(options)
      @relationships = filter_attributes_by_name(options[:relationships], self.class.relationships)
    end

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
