require 'fun_with_json_api/exception_serializer'

module FunWithJsonApi
  module ControllerMethods
    def render_fun_with_json_api_exception(exception)
      render json: exception,
             serializer: FunWithJsonApi::ExceptionSerializer,
             adapter: :json,
             status: exception.http_status
    end
  end
end
