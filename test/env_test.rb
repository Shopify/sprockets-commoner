require 'test_helper'

class EnvTest < MiniTest::Test
  def setup
    ENV['SOME_RANDOM_ENVIRONMENT_VARIABLE'] = 'yes_indeed'

    @env = Sprockets::Environment.new(File.join(__dir__, 'fixtures'))
    @env.append_path File.join(__dir__, 'fixtures')
  end

  def test_dependency
    assert asset = @env['process-env.js']
    assert_includes asset.metadata[:dependencies], 'commoner-environment-variable:NODE_ENV'
  end

  def test_dependency_value
    assert_equal @env.resolve_dependency('commoner-environment-variable:SOME_RANDOM_ENVIRONMENT_VARIABLE'), 'yes_indeed'
  end
end
