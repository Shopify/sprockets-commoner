require 'sprockets'
require 'sprockets/commoner/json_processor'
require 'sprockets/commoner/processor'
require 'sprockets/commoner/bundle'

module Sprockets
  module Commoner
  end

  register_postprocessor 'application/javascript', ::Sprockets::Commoner::Processor
  register_transformer 'application/json', 'application/javascript', ::Sprockets::Commoner::JSONProcessor
  register_bundle_metadata_reducer 'application/javascript', :commoner_enabled, false, :|
  register_bundle_metadata_reducer 'application/javascript', :commoner_used_helpers, Set.new, :+
  register_bundle_processor 'application/javascript', ::Sprockets::Commoner::Bundle
end

require 'sprockets/commoner/railtie' if defined?(Rails)
