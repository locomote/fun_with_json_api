require 'fun_with_json_api/controller_methods'
require 'fun_with_json_api/action_controller_extensions/serialization'
require 'fun_with_json_api/middleware/catch_json_api_parse_errors'

Mime::Type.register FunWithJsonApi::MEDIA_TYPE, :json_api

module FunWithJsonApi
  # Mountable engine for fun with json_api
  class Railtie < Rails::Railtie
    class ParseError < ::StandardError; end

    initializer :register_json_api_parser do |app|
      parsers =
        if Rails::VERSION::MAJOR >= 5
          ActionDispatch::Http::Parameters
        else
          ActionDispatch::ParamsParser
        end

      parsers::DEFAULT_PARSERS[Mime::Type.lookup(FunWithJsonApi::MEDIA_TYPE)] = lambda do |body|
        data = JSON.parse(body)
        data = { _json: data } unless data.is_a?(Hash)
        data.with_indifferent_access
      end

      # Add Middleware for catching parser errors
      app.config.middleware.insert_before(
        ActionDispatch::ParamsParser, 'FunWithJsonApi::Middleware::CatchJsonApiParseErrors'
      )
    end
    initializer :register_json_api_renderer do
      ActionController::Renderers.add :json_api do |json, options|
        json = json.to_json(options) unless json.is_a?(String)
        self.content_type ||= Mime::Type.lookup(FunWithJsonApi::MEDIA_TYPE)
        json
      end
    end
    initializer :register_json_api_serializers do
      ActiveSupport.on_load(:action_controller) do
        include(FunWithJsonApi::ActionControllerExtensions::Serialization)
      end
    end
    initializer :add_json_api_locales do
      translations = File.expand_path('../../../config/locales/**/*.{rb,yml}', __FILE__)
      Dir.glob(translations) { |f| config.i18n.load_path << f.to_s }
    end
  end
end
