module FunWithJsonApi
  module ActionControllerExtensions
    module Serialization
      # Overrides the dynamic render json_api methods to use ActiveModelSerializer
      [:_render_option_json_api, :_render_with_renderer_json_api].each do |renderer_method|
        define_method renderer_method do |resource, options|
          options.fetch(:adapter) { options[:adapter] ||= :json_api }
          options.fetch(:serialization_context) do
            options[:serialization_context] ||=
              ActiveModelSerializers::SerializationContext.new(request)
          end
          serializable_resource = get_serializer(resource, options)
          super(serializable_resource, options)
        end
      end
    end
  end
end
