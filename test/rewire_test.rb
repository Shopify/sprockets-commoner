require 'test_helper'

class RewireTest < MiniTest::Test
  def setup
    @env = Sprockets::Environment.new(File.join(__dir__, 'fixtures'))
    @env.append_path File.join(__dir__, 'fixtures')
  end

  def test_just_js
    assert asset = @env['scripts']
    assert_equal <<-JS.chomp, asset.to_s.chomp
!function() {
var __babel_node_initialize_module__ = function(f) {
  var module = {exports: {}};
  f.call(module.exports, module, module.exports);
  return module.exports;
};
var __babel_node_helper__createClass = function () {
  function defineProperties(target, props) {
    for (var i = 0; i < props.length; i++) {
      var descriptor = props[i];
      descriptor.enumerable = descriptor.enumerable || false;
      descriptor.configurable = true;
      if ("value" in descriptor) descriptor.writable = true;
      Object.defineProperty(target, descriptor.key, descriptor);
    }
  }

  return function (Constructor, protoProps, staticProps) {
    if (protoProps) defineProperties(Constructor.prototype, protoProps);
    if (staticProps) defineProperties(Constructor, staticProps);
    return Constructor;
  };
}(),
    __babel_node_helper__classCallCheck = function (instance, Constructor) {
  if (!(instance instanceof Constructor)) {
    throw new TypeError("Cannot call a class as a function");
  }
},
    __babel_node_helper__interopRequireDefault = function (obj) {
  return obj && obj.__esModule ? obj : {
    default: obj
  };
};
var __babel_node_module__scripts$module_js = __babel_node_initialize_module__(function (module, exports) {
  "use strict";

  Object.defineProperty(exports, "__esModule", {
    value: true
  });

  var Neato = function () {
    function Neato() {
      __babel_node_helper__classCallCheck(this, Neato);
    }

    __babel_node_helper__createClass(Neato, [{
      key: "whatever",
      value: function whatever() {
        return 3;
      }
    }]);

    return Neato;
  }();

  exports.default = Neato;
});
var __babel_node_module__scripts$index_js = __babel_node_initialize_module__(function (module, exports) {
  'use strict';

  Object.defineProperty(exports, "__esModule", {
    value: true
  });

  exports.default = function () {
    var b = new _module2.default();

    return b.whatever();
  };

  var _module = __babel_node_module__scripts$module_js;

  var _module2 = __babel_node_helper__interopRequireDefault(_module);
});
}();
    JS
  end

  def test_load_file
    assert asset = @env['arrow.js']
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
(function() {
  window.Whatever = 2;

}).call(this);
var __babel_node_module__arrow$second_js = __babel_node_initialize_module__(function (module, exports) {
  'use strict';

  var _extra = window.Whatever;

  var _extra2 = __babel_node_helper__interopRequireDefault(_extra);

  console.log(_extra2.default);
});
var __babel_node_module__arrow$index_js = __babel_node_initialize_module__(function (module, exports) {
  'use strict';

  var _extra = window.Whatever;

  var _extra2 = __babel_node_helper__interopRequireDefault(_extra);

  __babel_node_module__arrow$second_js;


  var a = function a(x) {
    return x * x;
  };

  console.log(a(_extra2.default));
});
}();
JS
  end

  def test_no_babel
    assert asset = @env['nobabelrc.js']
    assert_equal <<-JS.chomp, asset.to_s.chomp
const a = (x) => x * x;
JS
  end

  def test_from_coffee
    assert asset = @env['coffee-first.js']
    assert_equal <<-JS.chomp, asset.to_s.chomp
!function() {
var __babel_node_initialize_module__ = function(f) {
  var module = {exports: {}};
  f.call(module.exports, module, module.exports);
  return module.exports;
};

var __babel_node_module__coffee_first$included_js = __babel_node_initialize_module__(function (module, exports) {
  'use strict';

  Object.defineProperty(exports, "__esModule", {
    value: true
  });

  exports.default = function () {
    return 1;
  };

  window.Included = exports['default'] != null ? exports['default'] : exports;
});
(function() {
  console.log(window.Included);

}).call(this);

}();
    JS
  end

  def test_compress
    old_compressor = @env.js_compressor
    @env.js_compressor = :uglify

    assert asset = @env['arrow.js']
    assert_equal <<-JS.chomp, asset.to_s.chomp
!function(){var t=function(t){var e={exports:{}};return t.call(e.exports,e,e.exports),e.exports},e=function(t){return t&&t.__esModule?t:{"default":t}};(function(){window.Whatever=2}).call(this);t(function(t,n){"use strict";var o=window.Whatever,r=e(o);console.log(r["default"])}),t(function(t,n){"use strict";var o=window.Whatever,r=e(o),u=function(t){return t*t};console.log(u(r["default"]))})}();
JS
  ensure
    @env.js_compressor = old_compressor
  end
end
