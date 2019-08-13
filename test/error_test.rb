require 'test_helper'

class ErrorTest < MiniTest::Test
  def setup
    @env = Sprockets::Environment.new(File.join(__dir__, 'fixtures'))
    @env.append_path File.join(__dir__, 'fixtures')
  end

  def test_error
    error = assert_raises Schmooze::JavaScript::SyntaxError do
      @env['typo.js'].to_s
    end
    assert_equal <<-ERROR.strip, error.message.strip
#{File.join(__dir__, 'fixtures', 'typo', 'index.js')}: Unexpected keyword 'default' (1:4)

> 1 | var default = a;
    |     ^
  2 |
ERROR
  end
end
