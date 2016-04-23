module FunWithJsonApi
  class ExceptionPayloadSerializer < ::ActiveModel::Serializer
    attributes :id, :status, :code, :title, :detail, :source

    def attributes(*)
      # Strips all empty values and empty arrays
      super.select { |_k, v| v.present? }
    end

    def source
      {
        pointer: object.pointer,
        parameter: object.parameter
      }.select { |_k, v| v.present? }
    end
  end
end
