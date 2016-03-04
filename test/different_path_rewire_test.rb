require 'test_helper'

class DifferentPathRewireTest < MiniTest::Test
  def setup
    @env = Sprockets::Environment.new(File.join(__dir__, 'fixtures'))
    @env.append_path File.join(__dir__, 'fixtures', 'different-path')
  end

  def test_load_file
    assert asset = @env['absolute.js']
    assert_equal <<-JS.chomp, asset.to_s.chomp
!function() {
var __commoner_initialize_module__ = function(f) {
  var module = {exports: {}};
  f.call(module.exports, module, module.exports);
  return module.exports;
};
var global = window;

var __commoner_module__different_path$absolute$second_js = __commoner_initialize_module__(function (module, exports) {
  "use strict";

  console.log(1);
});
var __commoner_module__different_path$absolute$index_js = __commoner_initialize_module__(function (module, exports) {
  'use strict';

  console.log(2);
});
}();
JS
  end
end
