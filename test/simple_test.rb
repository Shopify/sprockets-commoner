require 'test_helper'

class SimpleTest < MiniTest::Test
  def setup
    @env = Sprockets::Environment.new(File.join(__dir__, 'fixtures'))
    @env.append_path File.join(__dir__, 'fixtures')
  end

  def test_load_file
    assert asset = @env['arrow.js']
    assert_equal <<-JS.chomp, asset.to_s
"use strict";

var a = function a(x) {
  return x * x;
};
    JS
  end

  def test_no_babel
    assert asset = @env['nobabelrc.js']
    assert_equal <<-JS.chomp, asset.to_s
const a = (x) => x * x;

    JS
  end
end
