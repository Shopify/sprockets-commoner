require 'sprockets'
require 'sprockets/commoner/json_processor'
require 'sprockets/commoner/jsx_processor'
require 'sprockets/commoner/processor'
require 'sprockets/commoner/bundle'

module Sprockets
  module Commoner
    def self.sprockets4?
      @@sprockets4 ||= Gem::Version.new(Sprockets::VERSION) >= Gem::Version.new('4.0.0.beta')
    end
  end

  register_mime_type "application/jsx", extensions: [".js.jsx",".jsx"], charset: :unicode
  register_postprocessor 'application/javascript', ::Sprockets::Commoner::Processor
  register_transformer 'application/json', 'application/javascript', ::Sprockets::Commoner::JSONProcessor
  register_transformer 'application/jsx', 'application/javascript', ::Sprockets::Commoner::JSXProcessor
  register_bundle_metadata_reducer 'application/javascript', :commoner_enabled, false, :|
  register_bundle_metadata_reducer 'application/javascript', :commoner_required, Set.new, :+
  register_bundle_metadata_reducer 'application/javascript', :commoner_used_helpers, Set.new, :+
  register_bundle_processor 'application/javascript', ::Sprockets::Commoner::Bundle
  register_dependency_resolver 'commoner-environment-variable' do |env, str|
    _, variable = str.split(':', 2)
    ENV[variable]
  end
end

require 'sprockets/commoner/railtie' if defined?(Rails)
