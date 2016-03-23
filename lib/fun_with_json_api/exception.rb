require 'fun_with_json_api/exception_payload'

module FunWithJsonApi
  class Exception < StandardError
    attr_reader :payload

    def initialize(message, payload)
      super(message)
      @payload = Array.wrap(payload)
    end

    # @return [Integer] The http status code for rendering this error
    def http_status
      payload_statuses = payload.map(&:status).uniq
      if payload_statuses.length == 1
        Integer(payload_statuses.first || '400') # Return the unique status code
      elsif payload_statuses.any? { |status| status.starts_with?('5') }
        500 # We have a server error
      else
        400 # Bad Request
      end
    end
  end
end

# Load known Exceptions
Dir["#{File.dirname(__FILE__)}/exceptions/**/*.rb"].each { |f| require f }
