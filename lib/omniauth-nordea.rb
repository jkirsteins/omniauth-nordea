require 'omniauth/nordea'
require 'i18n'
require 'pry'

I18n.load_path += Dir[File.join(File.dirname(__FILE__), 'omniauth', 'locales', '*.yml')]