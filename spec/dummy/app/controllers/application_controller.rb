class ApplicationController < ActionController::Base
  include FunWithJsonApi::ControllerMethods

  rescue_from FunWithJsonApi::Exception, with: :render_fun_with_json_api_exception

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def echo
    render json: params.slice(:data)
  end
end
