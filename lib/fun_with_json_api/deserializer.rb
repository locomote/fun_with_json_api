require 'active_support/inflector'
require 'fun_with_json_api/attribute'

module FunWithJsonApi
  class Deserializer
    class << self
      def create(options = {})
        new(options)
      end

      def id_param(id_param = nil)
        @id_param = id_param if id_param
        @id_param
      end

      def attribute(name, options = {})
        Attribute.create(name, options).tap do |attribute|
          define_method attribute.as do |value|
            attribute.call(value)
          end
          attributes << attribute
        end
      end

      def attributes
        @attributes ||= []
      end

      def belongs_to(name, type: nil, polymorphic: false)
        # type = !polymorphic && (type || model_type_from_name(name))
      end

      # rubocop:disable Style/PredicateName

      def has_many(name, type: nil)
        # puts FunWithJsonApi::Attributes::RelationshipsAttribute.new(name).inspect
      end

      # rubocop:enable Style/PredicateName
    end

    # Use DeserializerClass.create to build new instances
    private_class_method :new

    attr_reader :id_param
    attr_reader :attributes

    def initialize(options = {})
      @id_param = options.fetch(:id_param) { self.class.id_param }
      @attributes = self.class.attributes
      if options[:attributes]
        @attributes = @attributes.keep_if { |attr| options[:attributes].include?(attr.name) }
      end
    end

    # Takes a parsed params hash from ActiveModelSerializers::Deserialization and sanitizes values
    def sanitize_params(params)
      Hash[
        attribute_params(params)
      ]
    end

    private

    # Calls <attribute.as> on the current instance, override the #<as> method to change loading
    def attribute_params(params)
      attributes.map(&:as).select { |attribute| params.key?(attribute) }
                .map { |attribute| [attribute, public_send(attribute, params.fetch(attribute))] }
    end
  end
end
