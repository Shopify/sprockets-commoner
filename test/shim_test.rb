require 'test_helper'

class ShimTest < MiniTest::Test
  def setup
    @env = Sprockets::Environment.new(File.join(__dir__, 'fixtures'))
    @env.unregister_postprocessor('application/javascript', Sprockets::Commoner::Processor)
    @env.register_postprocessor('application/javascript', Sprockets::Commoner::Processor.new(
      @env.root,
      moduleShim: {
        'react/lib/ReactContext' => false
      }
    ))
    @env.append_path File.join(__dir__, 'fixtures')
  end

  def test_no_rewire
    assert asset = @env['shim.js']
    assert_equal <<-JS.chomp, asset.to_s.chomp
!function() {
var __commoner_initialize_module__ = function(f) {
  var module = {exports: {}};
  f.call(module.exports, module, module.exports);
  return module.exports;
};
var global = window;

var __commoner_module__shim$index_js = {};
}();
JS
  end
end
