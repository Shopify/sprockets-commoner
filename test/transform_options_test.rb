require 'test_helper'

class ExtraOptionsTest < MiniTest::Test
  def setup
    @env = Sprockets::Environment.new(File.join(__dir__, 'fixtures'))
    Sprockets::Commoner::Processor.configure(@env, transform_options: {
      'extra-options' => {
        globals: {
          'jquery' => '$'
        }
      }
    })
    @env.append_path File.join(__dir__, 'fixtures')
  end

  def test_transform_options
    assert asset = @env['extra-options.js']
    assert_equal <<-JS.chomp, asset.to_s.chomp
!function() {
var __commoner_initialize_module__ = function(f) {
  var module = {exports: {}};
  f.call(module.exports, module, module.exports);
  return module.exports;
};
var global = window;

var __commoner_module__extra_options$index_js = __commoner_initialize_module__(function (module, exports) {

  $.ajax('/whatever');
});
}();
JS
  end
end
