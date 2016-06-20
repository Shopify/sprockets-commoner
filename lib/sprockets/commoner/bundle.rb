require 'schmooze'

module Sprockets
  module Commoner
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
      return t.variableDeclarator(t.identifier('__commoner_helper__' + helper), babelHelpers.get(helper));
    })
  );
  return generator(declaration).code;
}
JS

      PRELUDE = <<-JS.freeze
!function() {
var __commoner_initialize_module__ = function(f) {
  var module = {exports: {}};
  f.call(module.exports, module, module.exports);
  return module.exports;
};
var global = window;
JS

      OUTRO = <<-JS.freeze
}();
JS
      def self.instance(env)
        @instance ||= new(env.root)
      end

      def self.call(input)
        instance(input[:environment]).call(input)
      end

      def call(input)
        return unless input[:metadata][:commoner_enabled]

        used_helpers = input[:metadata][:commoner_used_helpers]
        helpers = generate_helpers(used_helpers.to_a)
        {
          data: "#{PRELUDE}#{helpers}\n#{input[:data]}#{OUTRO}"
        }
      end
    end
  end
end
