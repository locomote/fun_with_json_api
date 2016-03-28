require 'fun_with_json_api/attribute'

module FunWithJsonApi
  # Provides a basic DSL for defining a FunWithJsonApi::Deserializer
  module DeserializerClassMethods
    def id_param(id_param = nil, format: false)
      @id_param = id_param.to_sym if id_param
      (@id_param || :id).tap do |param|
        if format
          attribute(:id, as: param, format: format) # Create a new id attribute
        end
      end
    end

    def type(type = nil)
      @type = type if type
      @type || type_from_class_name
    end

    def resource_class(resource_class = nil)
      @resource_class = resource_class if resource_class
      @resource_class || type_from_class_name.singularize.classify.constantize
    end

    # Attributes

    def attribute(name, options = {})
      Attribute.create(name, options).tap do |attribute|
        add_parse_attribute_method(attribute)
        attributes << attribute
      end
    end

    def attributes
      @attributes ||= []
    end

    # Relationships

    def belongs_to(name, deserializer_class_or_callable, options = {})
      Attributes::Relationship.create(
        name,
        deserializer_class_or_callable,
        options
      ).tap do |relationship|
        add_parse_attribute_method(relationship)
        relationships << relationship
      end
    end

    # rubocop:disable Style/PredicateName

    def has_many(name, deserializer_class_or_callable, options = {})
      Attributes::RelationshipCollection.create(
        name,
        deserializer_class_or_callable,
        options
      ).tap do |relationship|
        add_parse_attribute_method(relationship)
        relationships << relationship
      end
    end

    # rubocop:enable Style/PredicateName

    def relationships
      @relationships ||= []
    end

    private

    def add_parse_attribute_method(attribute)
      define_method(attribute.sanitize_attribute_method) do |param_value|
        attribute.call(param_value)
      end
    end

    def type_from_class_name
      if name.nil?
        Rails.logger.warn 'Unable to determine type for anonymous Deserializer'
        return nil
      end

      resource_class_name = name.demodulize.sub(/Deserializer/, '').underscore
      if ActiveModelSerializers.config.jsonapi_resource_type == :singular
        resource_class_name.singularize
      else
        resource_class_name.pluralize
      end
    end
  end
end
