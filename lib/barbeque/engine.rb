# Gems used by Barbeque::Engine
require 'rinku'

module Barbeque
  class Engine < ::Rails::Engine
    isolate_namespace Barbeque

    config.before_configuration do
      # Gems used by Barbeque::Engine, which also have Railtie or Mountable::Engine.
      # Railtie and Mountable::Engine aren't executed when required normally.
      require 'hamlit'
      require 'jquery-rails'
      require 'kaminari'
      require 'sprockets/railtie'
      require 'weak_parameters'
    end
  end
end
