module Barbeque
  class Engine < ::Rails::Engine
    isolate_namespace Barbeque

    config.before_configuration do
      # Listing gems which are mountable engine or have railtie.
      require 'adminlte2-rails'
      require 'coffee-rails'
      require 'hamlit'
      require 'jquery-rails'
      require 'kaminari'
      require 'sass-rails'
      require 'weak_parameters'
    end
  end
end
