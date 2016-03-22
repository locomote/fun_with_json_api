require 'fun_with_json_api/exception_payload'

module FunWithJsonApi
  class Exception < StandardError
    attr_reader :payload

    def initialize(message, payload)
      super(message)
      @payload = Array.wrap(payload)
    end
  end
end

# Load known Exceptions
Dir["#{File.dirname(__FILE__)}/exceptions/**/*.rb"].each { |f| require f }
