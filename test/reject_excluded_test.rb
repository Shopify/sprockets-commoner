require 'test_helper'

class RejectExcludedTest < MiniTest::Test
  def setup
    @env = Sprockets::Environment.new(File.join(__dir__, 'fixtures'))
    @env.unregister_postprocessor('application/javascript', Sprockets::Commoner::Processor)
    @env.register_postprocessor('application/javascript', Sprockets::Commoner::Processor.new(
      @env.root,
      exclude: ['dont-reject-unused/excluded.js', 'reject-excluded-files/excluded.js'],
    ))
    @env.append_path File.join(__dir__, 'fixtures')
  end

  def test_excluded_file
    assert_raises Sprockets::Commoner::Processor::ExcludedFileError do
      assert @env['reject-excluded-files.js']
    end
  end

  def test_dont_reject_if_not_using_result
    assert @env['dont-reject-unused.js']
  end
end
