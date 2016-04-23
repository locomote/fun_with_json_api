require 'fun_with_json_api/attribute'

module FunWithJsonApi
  # Provides a basic DSL for defining a FunWithJsonApi::Deserializer
  module DeserializerClassMethods
    def id_param(id_param = nil, format: false)
      lock.synchronize do
        @id_param = id_param.to_sym if id_param
      end
      (@id_param || :id).tap do |param|
        if format
          attribute(:id, as: param, format: format) # Create a new id attribute
        end
      end
    end

    def type(type = nil)
      lock.synchronize do
        @type = type if type
      end
      @type || type_from_class_name
    end

    def resource_class(resource_class = nil)
      lock.synchronize do
        @resource_class = resource_class if resource_class
      end
      @resource_class || type_from_class_name.singularize.classify.constantize
    end

    # Attributes

    def attribute(name, options = {})
      lock.synchronize do
        Attribute.create(name, options).tap do |attribute|
          add_parse_attribute_method(attribute)
          attributes << attribute
        end
      end
    end

    def attribute_names
      lock.synchronize { attributes.map(&:name) }
    end

    def build_attributes(names)
      lock.synchronize do
        names.map do |name|
          attribute = attributes.detect { |rel| rel.name == name }
          attribute.class.create(attribute.name, attribute.options)
        end
      end
    end

    # Relationships

    def belongs_to(name, deserializer_class_or_callable, options = {})
      lock.synchronize do
        Attributes::Relationship.create(
          name,
          deserializer_class_or_callable,
          options
        ).tap do |relationship|
          add_parse_resource_method(relationship)
          relationships << relationship
        end
      end
    end

    # rubocop:disable Style/PredicateName

    def has_many(name, deserializer_class_or_callable, options = {})
      lock.synchronize do
        Attributes::RelationshipCollection.create(
          name,
          deserializer_class_or_callable,
          options
        ).tap do |relationship|
          add_parse_resource_method(relationship)
          relationships << relationship
        end
      end
    end

    # rubocop:enable Style/PredicateName

    def relationship_names
      lock.synchronize { relationships.map(&:name) }
    end

    def build_relationships(options)
      lock.synchronize do
        options.map do |name, relationship_options|
          relationship = relationships.detect { |rel| rel.name == name }
          relationship.class.create(
            relationship.name,
            relationship.deserializer_class,
            relationship_options.reverse_merge(relationship.options)
          )
        end
      end
    end

    private

    def lock
      @lock ||= Mutex.new
    end

    def attributes
      @attributes ||= []
    end

    def relationships
      @relationships ||= []
    end

    def add_parse_attribute_method(attribute)
      define_method(attribute.sanitize_attribute_method) do |param_value|
        attribute_for(attribute.name).decode(param_value)
      end
    end

    def add_parse_resource_method(resource)
      define_method(resource.sanitize_attribute_method) do |param_value|
        relationship_for(resource.name).decode(param_value)
      end
    end

    def type_from_class_name
      if name.nil?
        Rails.logger.warn 'Unable to determine type for anonymous Deserializer'
        return nil
      end

      resource_class_name = name.demodulize.sub(/Deserializer/, '').underscore
      if ::ActiveModelSerializers.config.jsonapi_resource_type == :singular
        resource_class_name.singularize
      else
        resource_class_name.pluralize
      end
    end
  end
end
