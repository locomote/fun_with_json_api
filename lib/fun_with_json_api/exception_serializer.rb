require 'fun_with_json_api/exception_payload_serializer'

module FunWithJsonApi
  class ExceptionSerializer < ActiveModel::Serializer::CollectionSerializer
    def initialize(exception, options = {})
      super(exception.payload, options.reverse_merge(
        serializer: ExceptionPayloadSerializer
      ))
    end

    def root
      'errors'
    end
  end
end
