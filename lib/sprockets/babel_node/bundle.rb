require 'schmooze'

module Sprockets
  module BabelNode
    class Bundle < Schmooze::Base
      dependencies generator: 'babel-generator.default',
        babelHelpers: 'babel-helpers',
        t: 'babel-types'

      method :generate_helpers, <<-JS
function(helpers) {
  if (helpers.length === 0) {
    return '';
  }
  var declaration = t.variableDeclaration('var',
    helpers.map(function(helper) {
      return t.variableDeclarator(t.identifier('__babel_node_helper__' + helper), babelHelpers.get(helper));
    })
  );
  return generator(declaration).code;
}
JS

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
        @instance ||= new(input[:environment].root)
        @instance.call(input)
      end

      def call(input)
        return unless input[:metadata][:rewire_require_enabled]

        used_helpers = input[:metadata][:babel_node_used_helpers]
        helpers = generate_helpers(used_helpers.to_a)
        {
          data: "#{PRELUDE}#{helpers}\n#{input[:data]}#{OUTRO}"
        }
      end
    end
  end
end
