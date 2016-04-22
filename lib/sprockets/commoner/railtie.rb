module Sprockets
  module Commoner
    class Railtie < ::Rails::Railtie
      initializer 'sprockets-commoner' do
        config.assets.debug = false
        config.assets.paths << 'node_modules'
      end
    end
  end
end
