var __commoner_module__test$fixtures$shim$actual_js = __commoner_initialize_module__(function (module, exports) {
  'use strict';

  console.log(nonsense.process);

  var a = __commoner_module__node_modules$process$browser_js;
  console.log(__commoner_module__node_modules$process$browser_js.version);
  console.log(a.version);
  console.log(__commoner_module__node_modules$buffer$index_js.Buffer.isBuffer);

  (function (process) {
    console.log(process);
  })(1);
});
