require 'test_helper'

class ConfigureTest < MiniTest::Test
  def test_configure_twice
    env = Sprockets::Environment.new(File.join(__dir__, 'fixtures'))
    env.append_path File.join(__dir__, 'fixtures')
    # This tests configuring twice, to make sure the second call overwrites the first
    Sprockets::Commoner::Processor.configure(env, exclude: ['no-rewire/index.js'])
    Sprockets::Commoner::Processor.configure(env, exclude: [])

    assert asset = env['no-rewire.js']
    assert_equal <<-JS.chomp, asset.to_s.chomp
!function(global) {
var __commoner_initialize_module__ = function(f) {
  var module = {exports: {}};
  f.call(module.exports, module, module.exports);
  return module.exports;
};

var __commoner_module__no_rewire$index_js = __commoner_initialize_module__(function (module, exports) {
  "use strict";

  var a = 1;
});
}(typeof global != 'undefined' ? global : typeof window != 'undefined' ? window : this);
JS
  end
end
