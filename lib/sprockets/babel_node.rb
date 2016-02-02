require 'open3'
require 'sprockets/babel_node/common_finisher'
require 'sprockets/babel_node/vanilla_transformer'

module Sprockets
  class BabelNode
    PROCESSOR_PATH = File.join(__dir__, 'babel_node', 'processor.js')
    REWIRE_REQUIRE_PATH = File.expand_path('../../babel-plugin-rewire-require/', __dir__)

    def self.instance(environment)
      @instance ||= new(environment)
    end

    def self.call(input)
      instance(input[:environment]).call(input)
    end

    def initialize(environment)
      @stdin, @stdout, @wait_thr = Open3.popen2('node', '-e', File.read(PROCESSOR_PATH), chdir: environment.root, err: :err)
      msg = message('version')
      @cache_key = [
        self.class.name,
        msg['nodeVersion'],
        msg['babelVersion'],
        VERSION,
      ].freeze
    end

    def call(input)
      @commonjs_requires = Set.new(input[:metadata][:commonjs_requires])
      @dependencies      = Set.new(input[:metadata][:dependencies])
      @links             = Set.new(input[:metadata][:links])

      @filename = input[:filename]
      @dirname = File.dirname(@filename)
      @uri = input[:uri]
      @environment = input[:environment]
      @content_type = input[:content_type]

      data = input[:data]

      result = input[:cache].fetch(@cache_key + [input[:filename], data]) do
        value = message('transform', {
          'data' => data,
          'options' => options(input),
        })
        module_name = escape_path(modulename(input[:filename]))
        value['code'].prepend(",\n__babel_node_module__#{module_name}=__babel_node_module_initialize__(function(module, exports) {\n")
        value['code'] << "\n})"
        value
      end

      if result['metadata'].has_key?('requires')
        result['metadata']['requires'].each do |r|
          @commonjs_requires << resolve(r)
        end
      end

      {
        commonjs_requires: @commonjs_requires,
        dependencies: @dependencies,
        links: @links,
        data: result['code'],
        map: result['map'],
      }
    end

    private
      def escape_path(path)
        path.gsub!(/[^A-Za-z0-9_]/) {|c| if c == '/' then '$' else '_' end}
      end

      def modulename(filename)
        filename[@environment.root.size+1..-1]
      end

      def message(method, data={})
        @stdin.puts JSON.dump({'method' => method}.merge(data))
        status, return_value = JSON.parse(@stdout.gets)
        if status == 'ok' 
          return_value
        else
          raise Sprockets::Error, return_value
        end
      end

      def resolve(path)
        uri, deps = @environment.resolve!(path, accept: 'babel-node/commonjs-artifact', pipeline: :self, base_path: @dirname)
        @dependencies.merge(deps)
        uri
      end

      def options(input)
        {
          'ast' => false,
          'filename' => input[:filename],
          'filenameRelative' => PathUtils.split_subpath(input[:load_path], input[:filename]),
          'inputSourceMap' => input[:metadata][:map],
          'moduleRoot' => nil,
          'plugins' => [
            [REWIRE_REQUIRE_PATH, {rootDir: @environment.root, extensions: %w(.js .json .es6.js), paths: @environment.paths}]
          ],
          'sourceMap' => true,
          'sourceRoot' => input[:load_path],
        }
      end
  end

  register_mime_type 'babel-node/commonjs-artifact', extensions: ['.babel_node_commonjs'], charset: :unicode
  register_mime_type 'application/ecmascript-6', extensions: ['.es6.js'], charset: :unicode
  register_transformer 'application/ecmascript-6', 'babel-node/commonjs-artifact', BabelNode
  register_transformer 'application/javascript', 'babel-node/commonjs-artifact', BabelNode::VanillaTransformer
  register_transformer 'babel-node/commonjs-artifact', 'application/javascript', BabelNode::CommonFinisher
end
