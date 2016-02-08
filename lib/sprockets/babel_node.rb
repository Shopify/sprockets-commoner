require 'sprockets'
require 'sprockets/babel_node/processor'

module Sprockets
  module BabelNode
  end

  register_postprocessor 'application/javascript', ::Sprockets::BabelNode::Processor
end
