require 'test_helper'

class ReactTest < MiniTest::Test
  def setup
    @env = Sprockets::Environment.new(File.join(__dir__, 'fixtures'))
    @env.append_path File.join(__dir__, 'fixtures')
  end

  def test_react
    assert asset = @env['react.js']
    assert_equal <<-JS.chomp, asset.to_s.chomp
!function(global) {
var __commoner_initialize_module__ = function(f) {
  var module = {exports: {}};
  f.call(module.exports, module, module.exports);
  return module.exports;
};

var __commoner_module__react$render_jsx = __commoner_initialize_module__(function (module, exports) {
  ReactDOM.render(React.createElement(
    'h1',
    null,
    'Hello, world!'
  ), document.getElementById('root'));
});
var __commoner_module__react$index_js = {};
}(typeof global != 'undefined' ? global : typeof window != 'undefined' ? window : this);
JS
  end
end
