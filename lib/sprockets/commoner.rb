require 'sprockets'
require 'sprockets/commoner/processor'
require 'sprockets/commoner/bundle'

module Sprockets
  module Commoner
  end

  register_postprocessor 'application/javascript', ::Sprockets::Commoner::Processor
  register_bundle_metadata_reducer 'application/javascript', :rewire_require_enabled, false, :|
  register_bundle_metadata_reducer 'application/javascript', :commoner_used_helpers, Set.new, :+
  register_bundle_processor 'application/javascript', ::Sprockets::Commoner::Bundle
end
