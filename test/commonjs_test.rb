require 'test_helper'

class CommonjsTest < MiniTest::Test
  def setup
    @env = Sprockets::Environment.new(File.join(__dir__, 'fixtures'))
    @env.append_path File.join(__dir__, 'fixtures')
  end

  def test_simple
    assert asset = @env.find_asset("application", accept: "application/javascript")

    assert_equal 'application/javascript', asset.content_type
    assert_equal <<-JS.strip, asset.to_s.strip
!function() {
  var __babel_node_module_initialize__ = function(f) {
    var module = {exports: {}};
    f.call(module.exports, module, module.exports);
    return module.exports;
  }
,
__babel_node_module__arrow_es6_js=__babel_node_module_initialize__(function(module, exports) {
'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
$('body').text('GREAT SUCCESS');
var a = function a(x) {
  return x * x;
};
exports.default = a;
}),
__babel_node_module__imported2_es6_js=__babel_node_module_initialize__(function(module, exports) {
'use strict';

__babel_node_module__arrow_es6_js;
}),
__babel_node_module__imported_es6_js=__babel_node_module_initialize__(function(module, exports) {
'use strict';

__babel_node_module__imported2_es6_js;
});
}();
console.log("wow");
    JS
  end
end
