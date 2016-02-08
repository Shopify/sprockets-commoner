require 'open3'

module Sprockets
  module BabelNode
    class Processor
      Error = Class.new(::Sprockets::Error)

      PROCESSOR_PATH = File.join(__dir__, 'processor.js')
      BABELRC_FILE = '.babelrc'.freeze

      def self.instance(environment)
        @instance ||= new(environment)
      end

      def self.call(input)
        instance(input[:environment]).call(input)
      end

      def initialize(environment)
        @stdin, @stdout, @stderr, @wait_thr = Open3.popen3('node', '-e', File.read(PROCESSOR_PATH), chdir: environment.root)
        msg = message('version')
        @cache_key = [
          self.class.name,
          msg['nodeVersion'],
          msg['babelVersion'],
          VERSION,
        ].freeze
      end

      def call(input)
        return {data: input[:data]} if !has_babelrc?(input[:filename])

        # TODO(bouk): Add caching. Complicated by dependency on .babelrc files that can be anywhere up the tree, and potentially any of the packages mentioned in those files could have been upgraded
        result = message('transform', {
          'data' => input[:data],
          'options' => options(input),
        })

        {
          data: result['code'],
          map: result['map'],
        }
      end

      private
        def has_babelrc?(filename)
          loop do
            new_filename = File.dirname(filename)
            break if new_filename == filename
            filename = new_filename
            if File.exist?(File.join(filename, BABELRC_FILE))
              return true
            end
          end
          return false
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
          {
            'ast' => false,
            'filename' => input[:filename],
            'filenameRelative' => PathUtils.split_subpath(input[:load_path], input[:filename]),
            'inputSourceMap' => input[:metadata][:map],
            'moduleRoot' => nil,
            'sourceMap' => true,
            'sourceRoot' => input[:load_path],
          }
        end
    end
  end
end
