require 'test_helper'

class RejectExcludedTest < MiniTest::Test
  def setup
    @env = Sprockets::Environment.new(File.join(__dir__, 'fixtures'))
    @env.unregister_postprocessor('application/javascript', Sprockets::Commoner::Processor)
    @env.register_postprocessor('application/javascript', Sprockets::Commoner::Processor.new(
      @env.root,
      exclude: ['reject-excluded-files/excluded.js'],
    ))
    @env.append_path File.join(__dir__, 'fixtures')
  end

  def test_excluded_file
    assert_raises Sprockets::Commoner::Processor::ExcludedFileError do
      @env['reject-excluded-files.js'].to_s
    end
  end
end
