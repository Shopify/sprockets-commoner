require 'schmooze'
require 'open3'

module Sprockets
  module Commoner
    class Processor < Schmooze::Base

      ExcludedFileError = Class.new(::StandardError)

      VERSION = '1'.freeze
      BABELRC_FILE = '.babelrc'.freeze
      PACKAGE_JSON = 'package.json'.freeze
      JS_PACKAGE_PATH = File.expand_path('../../../js', __dir__)
      ALLOWED_EXTENSIONS = /\.js(?:\.erb)?\z/
      COFFEE_EXTENSION = /\.coffee(:?\.erb)?\z/

      dependencies babel: 'babel-core', commoner: 'babel-plugin-sprockets-commoner-internal'

      method :version, 'function() { return babel.version; }'
      method :transform, %q{function(code, opts, commonerOpts) {
  try {
    var file = new babel.File(opts);

    // The actual helpers are generated in bundle.rb
    file.set("helperGenerator", function(name) { return babel.types.identifier('__commoner_helper__' + name); });

    var commonerPlugin = babel.OptionManager.normalisePlugin(commoner);
    file.buildPluginsForOptions({plugins: [[commonerPlugin, commonerOpts]]});

    return file.wrap(code, function () {
      file.addCode(code);
      file.parseCode(code);
      return file.transform();
    });
  } catch (err) {
    if (err.codeFrame != null) {
      err.message += "\n";
      err.message += err.codeFrame;
    }
    throw err;
  }
}}
      def self.instance(env)
        @instance ||= new(env.root)
      end

      def self.call(input)
        instance(input[:environment]).call(input)
      end

      attr_reader :include, :exclude, :babel_exclude
      def initialize(root, include: [root], exclude: ['vendor/bundle'], babel_exclude: [/node_modules/])
        @include = include.map {|path| expand_to_root(path, root) }
        @exclude = exclude.map {|path| expand_to_root(path, root) }
        @babel_exclude = babel_exclude.map {|path| expand_to_root(path, root) }
        super(root, 'NODE_PATH' => JS_PACKAGE_PATH)
      end

      def cache_key
        @cache_key ||= [
          self.class.name,
          VERSION,
          version,
          @include.map(&:to_s),
          @exclude.map(&:to_s),
          @babel_exclude.map(&:to_s),
        ]
      end

      def call(input)
        filename = input[:filename]

        return unless should_process?(filename)

        @env = input[:environment]
        @required = input[:metadata][:required].to_a
        insertion_index = @required.index(input[:uri]) || -1
        @dependencies = Set.new(input[:metadata][:dependencies])


        babel_config = babelrc_data(filename)

        result = transform(input[:data], options(input), paths: @env.paths)

        if result['metadata'].has_key?('targetsToProcess')
          result['metadata']['targetsToProcess'].each do |t|
            unless should_process?(t)
              raise ExcludedFileError, "#{t} was imported from #{filename} but this file won't be processed by Sprockets::Commoner"
            end
          end
        end

        if result['metadata'].has_key?('required')
          result['metadata']['required'].each do |r|
            asset = resolve(r, accept: input[:content_type], pipeline: :self)
            @required.insert(insertion_index, asset)
          end
        end

        {
          data: result['code'],
          dependencies: @dependencies,
          required: Set.new(@required),

          commoner_used_helpers: Set.new(input[:metadata][:commoner_used_helpers]) + result['metadata']['usedHelpers'],
          commoner_enabled: input[:metadata][:commoner_enabled] | result['metadata']['commonerEnabled'],
        }
      end

      private
        def expand_to_root(path, root)
          if path.is_a?(String)
            File.expand_path(path, root)
          else
            path
          end
        end

        def should_process?(filename)
          return false unless ALLOWED_EXTENSIONS =~ filename
          return false unless self.include.empty? || match_any?(self.include, filename)
          return false if match_any?(self.exclude, filename)
          true
        end

        def match_any?(patterns, filename)
          patterns.any? { |pattern| pattern_match(pattern, filename) }
        end

        def pattern_match(pattern, filename)
          if pattern.is_a?(String)
            filename.start_with?(pattern)
          else
            pattern === filename
          end
        end

        def babelrc_data(filename)
          while filename != (filename = File.dirname(filename))
            begin
              name = File.join(filename, BABELRC_FILE)
              data = File.read(name)
              depend_on_file(name)
              return data
            rescue Errno::ENOENT
              name = File.join(filename, PACKAGE_JSON)
              data = package_babel_data(name)
              if data
                depend_on_file(name)
                return JSON.dump(data)
              else
                nil
              end
            end
          end
          return nil
        end

        def package_babel_data(filename)
          return JSON.parse(File.read(filename))['babel']
        rescue Errno::ENOENT
          return nil
        end

        def options(input)
          # TODO(bouk): Fix sourcemaps. Sourcemaps are only available in Sprockets v4
          {
            'ast' => false,
            'babelrc' => !match_any?(self.babel_exclude, input[:filename]),
            'filename' => input[:filename],
            'filenameRelative' => PathUtils.split_subpath(input[:load_path], input[:filename]),
            'moduleRoot' => nil,
            'sourceRoot' => @env.root,
          }
        end

        def resolve(path, **kargs)
          uri, deps = @env.resolve!(path, load_paths: [@env.root], **kargs)
          @dependencies.merge(deps)
          uri
        end

        def depend_on_file(path)
          uri, deps = @env.resolve!(path, load_paths: [@env.root])
          @dependencies.merge(deps)
          uri
        end
    end
  end
end
