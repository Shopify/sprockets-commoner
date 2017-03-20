require 'test_helper'

class CircularTest < MiniTest::Test
  def setup
    @env = Sprockets::Environment.new(File.join(__dir__, 'fixtures'))
    @env.append_path File.join(__dir__, 'fixtures')
  end

  def test_circular
    assert asset = @env['circular-dependency.js']
    assert_equal <<-JS.chomp, asset.to_s.chomp
!function(global) {
var __commoner_initialize_module__ = function(f) {
  var module = {exports: {}};
  f.call(module.exports, module, module.exports);
  return module.exports;
};

var __commoner_module__circular_dependency$a_js = __commoner_initialize_module__(function (module, exports) {
  'use strict';

  exports.f = function () {
    return __commoner_module__circular_dependency$b_js.value;
  };
  exports.value = 1;
});
var __commoner_module__circular_dependency$b_js = __commoner_initialize_module__(function (module, exports) {
  'use strict';

  exports.f = function () {
    return __commoner_module__circular_dependency$a_js.value;
  };
  exports.value = 2;
});
var __commoner_module__circular_dependency$index_js = __commoner_initialize_module__(function (module, exports) {
  'use strict';

  console.log(__commoner_module__circular_dependency$a_js.f(), __commoner_module__circular_dependency$b_js.f());
});
}(typeof global != 'undefined' ? global : typeof window != 'undefined' ? window : this);
JS
  end
end
