require 'test_helper'

class BabelRcExcludeTest < MiniTest::Test
  def setup
    @env = Sprockets::Environment.new(File.join(__dir__, 'fixtures'))
    Sprockets::Commoner::Processor.configure(@env, babel_exclude: [/excludeme/])
    @env.append_path File.join(__dir__, 'fixtures')
  end

  def test_stub
    assert asset = @env['babelrc-exclude.js']
    assert_equal <<-JS.chomp, asset.to_s.chomp
!function() {
var __commoner_initialize_module__ = function(f) {
  var module = {exports: {}};
  f.call(module.exports, module, module.exports);
  return module.exports;
};
var global = window;

var __commoner_module__babelrc_exclude$excludeme_js = __commoner_initialize_module__(function (module, exports) {
  export const a = 1;
});
var __commoner_module__babelrc_exclude$index_js = {};
}();
JS
  end
end
