module Sprockets
  module Commoner
    class Railtie < ::Rails::Railtie
      initializer 'sprockets-commoner' do
        # We need to disable debugging because otherwise Rails will include each file individually, while we need everything to be bundled up together into a single file.
        # ^ Not applicable to sprockets 4+
        config.assets.debug = false unless Commoner.sprockets4?
        config.assets.paths << 'node_modules'
      end
    end
  end
end
