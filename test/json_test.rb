require 'test_helper'

class JSONTest < MiniTest::Test
  def setup
    @env = Sprockets::Environment.new(File.join(__dir__, 'fixtures'))
    @env.append_path File.join(__dir__, 'fixtures')
  end

  def test_import_json
    assert asset = @env['import-json.js']
    assert_equal <<-JS.chomp, asset.to_s.chomp
!function(global) {
var __commoner_initialize_module__ = function(f) {
  var module = {exports: {}};
  f.call(module.exports, module, module.exports);
  return module.exports;
};

var __commoner_module__import_json$data_json = __commoner_initialize_module__(function (module, exports) {
  module.exports = {
    "extra_info": 123
  };
});
var __commoner_module__import_json$index_js = __commoner_initialize_module__(function (module, exports) {
  console.log(__commoner_module__import_json$data_json.extra_info);
});
}(typeof global != 'undefined' ? global : typeof window != 'undefined' ? window : this);
JS
  end
end
