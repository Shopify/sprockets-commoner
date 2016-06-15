require 'test_helper'

class CacheKeyTest < MiniTest::Test
  def setup
    @dir = File.join(__dir__, 'fixtures')
    @processor = Sprockets::Commoner::Processor.new(@dir)
  end

  def test_cache_key
    assert_equal ['Sprockets::Commoner::Processor', '2', '6.9.1', [@dir], [File.join(@dir, 'vendor/bundle')], [/node_modules/.to_s]], @processor.cache_key
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
