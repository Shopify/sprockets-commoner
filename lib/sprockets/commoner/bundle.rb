require 'schmooze'

module Sprockets
  module Commoner
    class Bundle < Schmooze::Base

      InaccessibleStubbedFileError = Class.new(::StandardError)

      JS_PACKAGE_PATH = File.expand_path('../../../js', __dir__)

      dependencies generator: 'babel-generator.default',
        babelHelpers: 'babel-helpers',
        t: 'babel-types',
        pathToIdentifier: 'babel-plugin-sprockets-commoner-internal/path-to-identifier'

      method :generate_header, <<-JS
function(helpers, globalIdentifiers) {
  var declarators = helpers.map(function(helper) {
    return t.variableDeclarator(t.identifier('__commoner_helper__' + helper), babelHelpers.get(helper));
  }).concat(globalIdentifiers.map(function(item) {
    return t.variableDeclarator(t.identifier(pathToIdentifier(item[0])), t.identifier(item[1]));
  }));
  if (declarators.length === 0) {
    return '';
  }
  var declaration = t.variableDeclaration('var', declarators);
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

if (typeof window !== 'undefined') {
  global = window;
} else if (typeof global !== 'undefined') {
  global = global;
} else {
  global = this;
}
JS

      OUTRO = <<-JS.freeze
}();
JS
      def initialize(root)
        super(root, 'NODE_PATH' => JS_PACKAGE_PATH)
      end

      def self.instance(env)
        @instance ||= new(env.root)
      end

      def self.call(input)
        env = input[:environment]
        instance(env).call(input)
      end

      def call(input)
        return unless input[:metadata][:commoner_enabled]
        env = input[:environment]
        # Get the filenames of all the assets that are included in the bundle
        assets_in_bundle = Set.new(input[:metadata][:included]) { |uri| env.load(uri).filename }
        # Subtract the assets in the bundle from those that are required. The missing assets were excluded through stubbing.
        assets_missing = input[:metadata][:commoner_required] - assets_in_bundle

        global_identifiers = assets_missing.map do |filename|
          uri, _ = if Commoner.sprockets4?
            env.resolve(filename, accept: input[:content_type], pipeline: :self)
          else
            env.resolve(filename, accept: input[:content_type], pipeline: :self, compat: false)
          end
          asset = env.load(uri)
          # Retrieve the global variable the file is exposed through
          global = asset.metadata[:commoner_global_identifier]
          raise InaccessibleStubbedFileError, "#{filename} is stubbed in #{input[:filename]} but doesn't define a global. Add an 'expose' directive." if global.nil?
          [filename.slice(env.root.size + 1, filename.size), global]
        end

        used_helpers = input[:metadata][:commoner_used_helpers].to_a
        header_code = generate_header(used_helpers, global_identifiers)
        {
          data: "#{PRELUDE}#{header_code}\n#{input[:data]}#{OUTRO}",
          map:  shift_map(input[:metadata][:map], PRELUDE.lines.count + header_code.lines.count),
        }
      end

      private

      def shift_map(map, offset)
        return unless map && Commoner.sprockets4?
        index_map = Sprockets::SourceMapUtils.make_index_map(map)
        index_map.merge({
          "sections" => index_map["sections"].map { |section|
            section.merge({
              "offset" => section["offset"].merge({
                "line" => section["offset"]["line"] + offset
              })
            })
          }
        })
      end
    end
  end
end
