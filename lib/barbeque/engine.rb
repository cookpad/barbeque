module Barbeque
  class Engine < ::Rails::Engine
    isolate_namespace Barbeque

    config.before_configuration do
      require 'kaminari'
    end
  end
end
