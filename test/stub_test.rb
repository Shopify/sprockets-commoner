require 'test_helper'

class StubTest < MiniTest::Test
  def setup
    @env = Sprockets::Environment.new(File.join(__dir__, 'fixtures'))
    @env.append_path File.join(__dir__, 'fixtures')
  end

  def test_stub
    assert asset = @env['vendor-stub.js']
    assert_equal <<-JS.chomp, asset.to_s.chomp
!function() {
var __babel_node_initialize_module__ = function(f) {
  var module = {exports: {}};
  f.call(module.exports, module, module.exports);
  return module.exports;
};
var __babel_node_helper__interopRequireDefault = function (obj) {
  return obj && obj.__esModule ? obj : {
    default: obj
  };
};
var __babel_node_module__vendor_stub$admin$whatever_js = __babel_node_initialize_module__(function (module, exports) {
  'use strict';

  var _jquery = $;

  var _jquery2 = __babel_node_helper__interopRequireDefault(_jquery);

  (0, _jquery2.default)(function () {
    return console.log('1337');
  });
});



}();
JS
  end
end
