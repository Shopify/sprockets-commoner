require 'schmooze'
require 'open3'

module Sprockets
  module Commoner
    class Processor < Schmooze::Base
      BABELRC_FILE = '.babelrc'.freeze
      PACKAGE_JSON = 'package.json'.freeze
      JS_PACKAGE_PATH = File.expand_path('../../../js', __dir__)
      ALLOWED_EXTENSIONS = /\.js(?:\.erb)?\z/

      dependencies babel: 'babel-core'

      method :version, 'function() { return [process.version, babel.version]; }'
      method :transform, 'babel.transform'

      def self.call(input)
        @instance ||= new(input[:environment].root)
        @instance.call(input)
      end

      def initialize(root)
        super(root, 'NODE_PATH' => JS_PACKAGE_PATH)

        @cache_key = [
          self.class.name,
          version,
          VERSION,
        ].freeze
      end

      def call(input)
        filename = input[:filename]

        return unless ALLOWED_EXTENSIONS =~ filename && babel_config = babelrc_data(filename)

        @env = input[:environment]
        @required = Set.new(input[:metadata][:required])
        @dependencies = Set.new(input[:metadata][:dependencies])

        result = input[:cache].fetch([filename, @cache_key, input[:data], babel_config]) do
          transform(input[:data], options(input))
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

          commoner_used_helpers: Set.new(input[:metadata][:commoner_used_helpers]) + result['metadata']['usedHelpers'],
          commoner_enabled: input[:metadata][:commoner_enabled] | result['metadata']['commonerEnabled'],
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

        def options(input)
          # TODO(bouk): Fix sourcemaps. Sourcemaps are only available in Sprockets v4
          {
            'ast' => false,
            'filename' => input[:filename],
            'filenameRelative' => PathUtils.split_subpath(input[:load_path], input[:filename]),
            'moduleRoot' => nil,
            'plugins' => [
              ['commoner-options', {
                # commoner looks for this property to copy options over from
                # This makes it possible for Sprockets to pass on options to commoner, while also having options in .babelrc
                # commoner does a shallow merge of what is defined in .babelrc and what is defined here
                # In the future (Sprockets 4 probably) we can also use this to pass on extensions
                __commoner_options: true,
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
