require 'sprockets'
require 'sprockets/babel_node/processor'
require 'sprockets/babel_node/bundle'

module Sprockets
  module BabelNode
  end

  register_postprocessor 'application/javascript', ::Sprockets::BabelNode::Processor
  register_bundle_metadata_reducer 'application/javascript', :rewire_require_enabled, false, :|
  register_bundle_metadata_reducer 'application/javascript', :babel_node_used_helpers, Set.new, :+
  register_bundle_processor 'application/javascript', ::Sprockets::BabelNode::Bundle
end
