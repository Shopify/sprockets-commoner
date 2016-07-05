require 'test_helper'

class CacheKeyTest < MiniTest::Test
  def setup
    @dir = File.join(__dir__, 'fixtures')
  end

  def test_default_cache_key
    processor = Sprockets::Commoner::Processor.new(@dir)
    assert_equal ['Sprockets::Commoner::Processor', '2', '6.9.1', [@dir], [File.join(@dir, 'vendor/bundle')], [/node_modules/.to_s], []], processor.cache_key
  end

  def test_opts_cache_key
    processor = Sprockets::Commoner::Processor.new(@dir, transform_options: {
      /index.js$/ => {
        globals: {
          'jquery' => '$'
        }
      }
    })
    assert_equal ['Sprockets::Commoner::Processor', '2', '6.9.1', [@dir], [File.join(@dir, 'vendor/bundle')], [/node_modules/.to_s], [[/index.js$/.to_s, {globals: {'jquery' => '$'}}]]], processor.cache_key
  end

  def test_babel_missing_cache_key
    error = assert_raises Schmooze::DependencyError do
      Dir.mktmpdir do |dir|
        Sprockets::Commoner::Processor.new(dir).cache_key
      end
    end

    assert_equal 'Cannot determine babel version as babel-core has not been installed', error.message
  end
end
