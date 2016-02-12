module Sprockets
  module BabelNode
    class Bundle
      Error = Class.new(::Sprockets::Error)

      PRELUDE = <<-JS.freeze
!function() {
var __babel_node_initialize_module__ = function(f) {
  var module = {exports: {}};
  f.call(module.exports, module, module.exports);
  return module.exports;
};
JS

      OUTRO = <<-JS.freeze

}();
JS

      def self.call(input)
        return unless input[:metadata][:rewire_require_enabled]

        used_helpers = input[:metadata][:babel_node_used_helpers]
        helpers = generate_helpers(input, *used_helpers)
        {
          data: "#{PRELUDE}#{helpers}\n#{input[:data]}#{OUTRO}"
        }
      end

      def self.generate_helpers(input, *helpers)
        if helpers.empty?
          ''
        else
          ::Sprockets::BabelNode::Processor.instance(input[:environment]).send(:message, 'helpers', helpers: helpers)['code']
        end
      end
    end
  end
end
