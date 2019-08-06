require 'test_helper'

class RewireTest < MiniTest::Test
  def setup
    @env = Sprockets::Environment.new(File.join(__dir__, 'fixtures'))
    @env.append_path File.join(__dir__, 'fixtures')
  end

  def test_just_js
    assert asset = @env['scripts.js']
    assert_equal <<-JS.chomp, asset.to_s.chomp
!function(global) {
var __commoner_initialize_module__ = function(f) {
  var module = {exports: {}};
  f.call(module.exports, module, module.exports);
  return module.exports;
};
var __commoner_helper__createClass = function () {
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
    __commoner_helper__classCallCheck = function (instance, Constructor) {
  if (!(instance instanceof Constructor)) {
    throw new TypeError("Cannot call a class as a function");
  }
},
    __commoner_helper__interopRequireDefault = function (obj) {
  return obj && obj.__esModule ? obj : {
    default: obj
  };
};
var __commoner_module__scripts$module_js = __commoner_initialize_module__(function (module, exports) {
  "use strict";

  Object.defineProperty(exports, "__esModule", {
    value: true
  });

  var Neato = function () {
    function Neato() {
      __commoner_helper__classCallCheck(this, Neato);
    }

    __commoner_helper__createClass(Neato, [{
      key: "whatever",
      value: function whatever() {
        return 3;
      }
    }]);

    return Neato;
  }();

  exports.default = Neato;
});
var __commoner_module__scripts$index_js = __commoner_initialize_module__(function (module, exports) {
  'use strict';

  Object.defineProperty(exports, "__esModule", {
    value: true
  });

  exports.default = function () {
    var b = new _module2.default();

    return b.whatever();
  };

  var _module2 = __commoner_helper__interopRequireDefault(__commoner_module__scripts$module_js);
});
}(typeof global != 'undefined' ? global : typeof window != 'undefined' ? window : this);
    JS
  end

  def test_load_file
    assert asset = @env['arrow.js']
    assert_equal <<-JS.chomp, asset.to_s.chomp
!function(global) {
var __commoner_initialize_module__ = function(f) {
  var module = {exports: {}};
  f.call(module.exports, module, module.exports);
  return module.exports;
};
var __commoner_helper__interopRequireDefault = function (obj) {
  return obj && obj.__esModule ? obj : {
    default: obj
  };
};
(function() {
  window.Whatever = 2;

}).call(this);
var __commoner_module__arrow$second_js = __commoner_initialize_module__(function (module, exports) {
  'use strict';

  var _extra2 = __commoner_helper__interopRequireDefault(window.Whatever);

  console.log(_extra2.default);
});
var __commoner_module__arrow$empty_js = {};
var __commoner_module__arrow$index_js = __commoner_initialize_module__(function (module, exports) {
  'use strict';

  var _extra2 = __commoner_helper__interopRequireDefault(window.Whatever);

  var a = function a(x) {
    return x * x;
  };

  console.log(a(_extra2.default));
});
}(typeof global != 'undefined' ? global : typeof window != 'undefined' ? window : this);
JS
  end

  def test_from_coffee
    assert asset = @env['coffee-first.js']
    assert_equal <<-JS.chomp, asset.to_s.chomp
!function(global) {
var __commoner_initialize_module__ = function(f) {
  var module = {exports: {}};
  f.call(module.exports, module, module.exports);
  return module.exports;
};

(function() {
  window.A = 1;

}).call(this);
var __commoner_module__coffee_first$included_js = __commoner_initialize_module__(function (module, exports) {
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
}(typeof global != 'undefined' ? global : typeof window != 'undefined' ? window : this);
    JS
  end

  def test_compress
    old_compressor = @env.js_compressor
    @env.js_compressor = :uglify

    assert asset = @env['arrow.js']
    assert_equal <<-JS.chomp, asset.to_s.chomp
!function(){var e=function(e){var n={exports:{}};return e.call(n.exports,n,n.exports),n.exports},o=function(e){return e&&e.__esModule?e:{"default":e}};(function(){window.Whatever=2}).call(this);e(function(){"use strict";var e=o(window.Whatever);console.log(e["default"])}),e(function(){"use strict";var e=o(window.Whatever),n=function n(e){return e*e};console.log(n(e["default"]))})}("undefined"!=typeof global?global:"undefined"!=typeof window&&window);
JS
  ensure
    @env.js_compressor = old_compressor
  end

  def test_require_self_js
    assert asset = @env['scripts-require_self.js']
    assert_equal <<-JS.chomp, asset.to_s.chomp
!function(global) {
var __commoner_initialize_module__ = function(f) {
  var module = {exports: {}};
  f.call(module.exports, module, module.exports);
  return module.exports;
};
var __commoner_helper__createClass = function () {
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
    __commoner_helper__classCallCheck = function (instance, Constructor) {
  if (!(instance instanceof Constructor)) {
    throw new TypeError("Cannot call a class as a function");
  }
},
    __commoner_helper__interopRequireDefault = function (obj) {
  return obj && obj.__esModule ? obj : {
    default: obj
  };
};
var __commoner_module__scripts_require_self$module_js = __commoner_initialize_module__(function (module, exports) {
  "use strict";

  Object.defineProperty(exports, "__esModule", {
    value: true
  });

  var Neato = function () {
    function Neato() {
      __commoner_helper__classCallCheck(this, Neato);
    }

    __commoner_helper__createClass(Neato, [{
      key: "whatever",
      value: function whatever() {
        return 3;
      }
    }]);

    return Neato;
  }();

  exports.default = Neato;
});
var __commoner_module__scripts_require_self$index_js = __commoner_initialize_module__(function (module, exports) {
  'use strict';

  Object.defineProperty(exports, "__esModule", {
    value: true
  });

  exports.default = function () {
    var b = new _module2.default();

    return b.whatever();
  };

  var _module2 = __commoner_helper__interopRequireDefault(__commoner_module__scripts_require_self$module_js);
});
}(typeof global != 'undefined' ? global : typeof window != 'undefined' ? window : this);
    JS
  end
end
