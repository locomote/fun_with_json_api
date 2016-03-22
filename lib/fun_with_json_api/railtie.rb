module FunWithJsonApi
  # Mountable engine for fun with json_api
  class Railtie < Rails::Railtie
    initializer 'fun_with_json_api.add_locales' do
      translations = File.expand_path('../../../config/locales/**/*.{rb,yml}', __FILE__)
      Dir.glob(translations) { |f| config.i18n.load_path << f.to_s }
    end
  end
end
