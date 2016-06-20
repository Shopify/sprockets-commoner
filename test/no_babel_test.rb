require 'test_helper'

class NoBabelTest < MiniTest::Test
  def setup
    @env = Sprockets::Environment.new(File.join(__dir__, 'fixtures'))
    Sprockets::Commoner::Processor.configure(@env, exclude: ['nobabelrc/index.js'])
    @env.append_path File.join(__dir__, 'fixtures')
  end

  def test_no_babel
    assert asset = @env['nobabelrc.js']
    assert_equal <<-JS.chomp, asset.to_s.chomp
const a = (x) => x * x;
JS
  end
end
