module Sprockets
  class BabelNode
    class CommonFinisher
      PRELUDE = <<-JS.freeze
!function() {
  var __babel_node_module_initialize__ = function(f) {
    var module = {exports: {}};
    f.call(module.exports, module, module.exports);
    return module.exports;
  }
JS

      OUTRO = ";\n}();".freeze

      def self.call(input)
        env  = input[:environment]
        type = input[:content_type]

        dependencies = Set.new(input[:metadata][:dependencies])
        find_commonjs_requires = proc { |uri| env.load(uri).metadata[:commonjs_requires] }
        commonjs_requires = input[:metadata][:commonjs_requires].map do |dep|
          Utils.dfs(dep, &find_commonjs_requires)
        end.reduce(Set.new, :+)

        assets = commonjs_requires.map do |uri|
          asset = env.load(uri)
          dependencies.merge(asset.metadata[:dependencies])
          asset.source
        end
        assets << input[:data]

        {
          data: combine_assets(assets),
          dependencies: dependencies
        }
      end

      def self.combine_assets(assets)
        code = PRELUDE.dup
        code << assets.join
        code << OUTRO
        code
      end
    end
  end
end
