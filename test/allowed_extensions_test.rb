require 'test_helper'

class AllowedExtensionsTest < MiniTest::Test
  def setup
    @env = Sprockets::Environment.new(File.join(__dir__, 'fixtures'))
    @processor = Sprockets::Commoner::Processor.new(@env.root)
  end

  def test_allowed_extensions
    assert @processor.send('should_process?', "#{@env.root}/my-lib.js")
    assert @processor.send('should_process?', "#{@env.root}/my-lib.js.erb")
    assert @processor.send('should_process?', "#{@env.root}/my-lib.json")
    assert @processor.send('should_process?', "#{@env.root}/my-lib.json.erb")
    assert @processor.send('should_process?', "#{@env.root}/myComponent.jsx")
    assert @processor.send('should_process?', "#{@env.root}/myComponent.jsx.erb")
  end

  def test_forbidden_extensions
    assert !@processor.send('should_process?', "#{@env.root}/my-lib.jso")
    assert !@processor.send('should_process?', "#{@env.root}/my-lib.jsxon")
    assert !@processor.send('should_process?', "#{@env.root}/my-lib.jsonx")
  end
end
