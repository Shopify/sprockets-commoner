require 'test_helper'

class StubTest < MiniTest::Test
  def setup
    @env = Sprockets::Environment.new(File.join(__dir__, 'fixtures'))
    Sprockets::Commoner::Processor.configure(@env, transform_options: {
      'vendor-stub/admin' => {
        globals: {
          'jquery' => '$'
        }
      }
    })
    @env.append_path File.join(__dir__, 'fixtures')
  end

  def test_stub
    assert asset = @env['vendor-stub.js']
    assert_equal <<-JS.chomp, asset.to_s.chomp
!function() {
var __commoner_initialize_module__ = function(f) {
  var module = {exports: {}};
  f.call(module.exports, module, module.exports);
  return module.exports;
};
var global = window;
var __commoner_helper__interopRequireDefault = function (obj) {
  return obj && obj.__esModule ? obj : {
    default: obj
  };
},
    __commoner_module__vendor_stub$stubme_js = window.Important;
var __commoner_module__vendor_stub$admin$whatever_js = __commoner_initialize_module__(function (module, exports) {
  'use strict';

  var _jquery2 = __commoner_helper__interopRequireDefault($);

  var _stubme2 = __commoner_helper__interopRequireDefault(__commoner_module__vendor_stub$stubme_js);

  (0, _jquery2.default)(function () {
    return console.log('1337', _stubme2.default);
  });
});
var __commoner_module__vendor_stub$index_js = {};
}();
JS
  end
end
