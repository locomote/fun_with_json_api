module FunWithJsonApi
  module Middleware
    class CatchJsonApiParseErrors
      def initialize(app)
        @app = app
      end

      def call(env)
        @app.call(env)
      rescue ActionDispatch::ParamsParser::ParseError => error
        if env['CONTENT_TYPE'] == FunWithJsonApi::MEDIA_TYPE && respond_with_json_api_error?(env)
          build_json_api_parse_error_response
        else
          raise error
        end
      end

      private

      def build_json_api_parse_error_response
        title = I18n.t('fun_with_json_api.exceptions.invalid_request_body')
        [
          400, { 'Content-Type' => FunWithJsonApi::MEDIA_TYPE },
          [
            { errors: [{ code: 'invalid_request_body', title: title, status: '400' }] }.to_json
          ]
        ]
      end

      def respond_with_json_api_error?(env)
        FunWithJsonApi.configuration.force_render_parse_errors_as_json_api? ||
          env['HTTP_ACCEPT'] =~ %r{application\/vnd\.api\+json}
      end
    end
  end
end
