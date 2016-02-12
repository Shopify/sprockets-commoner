require 'test_helper'

class SimpleTest < MiniTest::Test
  def setup
    @env = Sprockets::Environment.new(File.join(__dir__, 'fixtures'))
    @env.append_path File.join(__dir__, 'fixtures')
  end

  def test_no_rewire
    assert asset = @env['no-rewire.js']
    assert_equal <<-JS.chomp, asset.to_s.chomp
"use strict";

var a = 1;
JS
  end
end
