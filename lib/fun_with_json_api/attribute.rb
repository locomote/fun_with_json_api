module FunWithJsonApi
  class Attribute
    attr_reader :name
    attr_reader :as

    def self.create(name, options = {})
      format = options.fetch(:format, 'string')
      attribute_class_name = "#{format.to_s.classify}Attribute"
      if FunWithJsonApi::Attributes.const_defined?(attribute_class_name)
        FunWithJsonApi::Attributes.const_get(attribute_class_name)
      else
        raise ArgumentError, "Unknown attribute type: #{format}"
      end.new(name, options)
    end

    def initialize(name, options = {})
      raise ArgumentError, 'name cannot be blank!' unless name.present?

      @name = name
      @as = options.fetch(:as, name)
    end

    def call(value)
      value
    end

    def inspect
      "#<#{self.class.name}{name:#{name},as:#{as}}>"
    end
  end
end

# Load pre-defined Attributes
Dir["#{File.dirname(__FILE__)}/attributes/**/*.rb"].each { |f| require f }
