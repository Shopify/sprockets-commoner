require 'open3'

module Sprockets
  module BabelNode
    class Processor
      Error = Class.new(::Sprockets::Error)

      PROCESSOR_PATH = File.join(__dir__, 'processor.js')
      BABELRC_FILE = '.babelrc'.freeze
      PACKAGE_JSON = 'package.json'.freeze
      JS_PACKAGE_PATH = File.expand_path('../../../js', __dir__)
      ALLOWED_EXTENSIONS = /\.js(?:\.erb)?\z/

      def self.instance(environment)
        @instance ||= new(environment)
      end

      def self.call(input)
        instance(input[:environment]).call(input)
      end

      def initialize(environment)
        @stdin, @stdout, @stderr, @wait_thr = Open3.popen3(
          {"NODE_PATH" => JS_PACKAGE_PATH},
          'node',
          '-e',
          File.read(PROCESSOR_PATH),
          chdir: environment.root
        )
        msg = message('version')
        @cache_key = [
          self.class.name,
          msg['nodeVersion'],
          msg['babelVersion'],
          VERSION,
        ].freeze
      end

      def call(input)
        filename = input[:filename]

        return unless ALLOWED_EXTENSIONS =~ filename && babel_config = babelrc_data(filename)

        @env = input[:environment]
        @required = Set.new(input[:metadata][:required])
        @dependencies = Set.new(input[:metadata][:dependencies])

        result = input[:cache].fetch([@cache_key, input[:data], babel_config]) do
          message('transform', {
            'data' => input[:data],
            'options' => options(input),
          })
        end

        if result['metadata'].has_key?('requires')
          result['metadata']['requires'].each do |r|
            asset = resolve(r, accept: input[:content_type], pipeline: :self)
            @required << asset
          end
        end

        {
          data: result['code'],
          dependencies: @dependencies,
          required: @required,

          babel_node_used_helpers: Set.new(input[:metadata][:babel_node_used_helpers]) + result['metadata']['usedHelpers'],
          rewire_require_enabled: input[:metadata][:rewire_require_enabled] | result['metadata']['rewireRequireEnabled'],
        }
      end

      private
        def babelrc_data(filename)
          loop do
            new_filename = File.dirname(filename)
            break if new_filename == filename
            filename = new_filename
            begin
              return File.read(File.join(filename, BABELRC_FILE))
            rescue
              data = package_babel_data(File.join(filename, PACKAGE_JSON))
              return JSON.dump(data) if data
            end
          end
          return nil
        end

        def package_babel_data(filename)
          return JSON.parse(File.read(filename))['babel']
        rescue
          return nil
        end

        def message(method, data={})
          @stdin.puts JSON.dump({'method' => method}.merge(data))
          input = @stdout.gets
          if input.nil?
            raise Errno::EPIPE, "Can't read from stdout"
          end
          status, return_value = JSON.parse(input)
          if status == 'ok'
            return_value
          else
            raise Sprockets::Error, return_value
          end
        rescue Errno::EPIPE
          self.class.instance_variable_set(:@instance, nil)
          raise Error, @stderr.read
        end

        def options(input)
          # TODO(bouk): Fix sourcemaps. Sourcemaps are only available in Sprockets v4
          {
            'ast' => false,
            'filename' => input[:filename],
            'filenameRelative' => PathUtils.split_subpath(input[:load_path], input[:filename]),
            'moduleRoot' => nil,
            'plugins' => [
              ['rewire-require-options', {
                # rewire-require looks for this property to copy options over from
                # This makes it possible for Sprockets to pass on options to rewire-require, while also having options in .babelrc
                # rewire-require does a shallow merge of what is defined in .babelrc and what is defined here
                # In the future (Sprockets 4 probably) we can also use this to pass on extensions
                __rewire_require_options: true,
                paths: @env.paths,
              }],
            ],
            'sourceRoot' => @env.root,
          }
        end

        def resolve(path, **kargs)
          uri, deps = @env.resolve!(path, **kargs)
          @dependencies.merge(deps)
          uri
        end
    end
  end
end
