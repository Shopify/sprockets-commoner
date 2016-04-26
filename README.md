# Sprockets::Commoner

`Sprockets::Commoner` is a gem that enables JavaScript package and Babel transformation in Sprockets.

## Features

* Compile JavaScript modules into a single bundle.
* Run Babel transforms.
* Easy setup. We adhere to the Rails Way™ and don't require any additional configuration for the simplest and most common set ups.
* Integrate tightly into Sprockets/Rails. You can use any of Sprockets' features like ERB inside your files without having to jump through crazy hoops.
* Designed to emit code that compresses incredibly well. The code generated will be smaller than webpack or browserify.
* Use `process.env` inside your JavaScript. This will also run on anything in `node_modules` (e.g. Babel), to ensure dependencies are also compressed optimally.
* Automatic deduplication of Babel helpers. No need to use `babel-runtime`, as commoner will automatically detect which helpers are used and share them between modules in a way that compressed very well.

## Setup

### Requirements

1. Ruby v2+.
2. Rails/Any other application that uses Sprockets.
2. NPM v3+. We only support version 3 because commoner doesn't do any sort of deduplication of dependencies, so you could end up with a huge bundle if you don't want out. We only test against version 3, so you will definitely run into issues when running version 2.
3. We recommend and support version 4+ of Node.js.

### 10-second simple set up

To get started, let's begin with the simplest possible set up: just enabling resolving of `require`.

1. Add `sprockets-commoner` to Gemfile, run `bundle install`, and restart your Rails server.
1. Add package.json with `babel-core` version 6 and any packages you want. For the example, we'll use the excellent [lodash](https://lodash.com) library. `npm install -S babel-core@6 lodash`
1. `require` your client-side JavaScript packages from `application.js`!
```
var _ = require('lodash');

console.log(_.map([1, 2, 3], function(n) { return n * 3; }));
```

### Enabling Babel transforms

1. Install any Babel plugins or presets you want to use. We'll use the default ES2015 preset; `npm install babel-preset-es2015`.
1. Add a `.babelrc` with you required configuration. We just need to do `echo '{presets: ["es2015"]}' > .babelrc`.
1. Use any feature you want! For example, let's use `import` and arrow functions in our `application.js`:

```
import {map} from 'lodash';

console.log(map([1, 2, 3], (n) => n * 3));
```

### Advanced configuration

#### Fine-tuned selection of files to process

By default, commoner will process any file under the application root directory. If you want more fine-tuned control over which files to process, you can specify which paths to include or exclude. To do so, you will need to re-register the Sprockets processor. For example:

```
# In config/initializers/sprockets_commoner.rb
Rails.application.config.assets.configure do |env|
  env.unregister_postprocessor('application/javascript', Sprockets::Commoner::Processor)
  env.register_postprocessor('application/javascript', Sprockets::Commoner::Processor.new(
    env.root,
    # include, exclude, and babel_exclude patterns can be path prefixes or regexes.
    # Explicitely list paths to include. The default is `[env.root]`
    include: [File.join(env.root, 'app/assets/javascripts/subdirectory')],
    # List files to ignore and not process require calls or apply any Babel transforms to. Default is empty.
    exclude: [/ignored/],
    # Anything listed in babel_exclude has its require calls resolved, but no transforms listed in .babelrcs applied.
    # Default is [/node_modules/]
    babel_exclude: [/node_modules/]
  ))
end
```

## CoffeeScript interoperability

Commoner is designed from the start as a tool that facilitates a transition from CoffeeScript to ES2015. This is the reason it has a couple of features to make this easier.

### Importing CoffeeScript files

Any JavaScript file can `require` a CoffeeScript file, which will cause that CoffeeScript file to be scanned for a global variable reference and the `require` call to be replaced with a reference.
If we have the following two files:

```
# file.coffee
class window.ImportantClass
```

```
// main.js
var klass = require('./file');

new klass();
```

Then the second file will just be compiled down to `new window.ImportantClass()`. Importing global references works for global assignments and class definitions.

### Expose

We have added a custom directive that makes it very easy to expose an ES2015 module to the global namespace so it can be used by CoffeeScript files or any other code. For example:

```
'expose window.MyClass`;

export default class MyClass {}
```

`expose` will use the default export if available, otherwise the whole module namespace will be assigned to the global variable. For example:

```
// constants.js
'expose window.Constants';

export const A = 1;
export const B = 2;
export const C = 3;
```

This will make `window.Constants` equal `{A: 1, B: 2, C: 3}`.

## Methodology

Commoner registers a postprocessor that takes any `application/javascript` file and passes it through Babel.

### `require` support

`Sprockets::Commoner` enables support for `require()` by replacing `require` function calls with variable references. It does this by assigning every file a unique identifier based on their filename. For example, if the file you're referencing is located at `<root>/node_modules/package/index.js` it will get the name `__commoner_module__node_modules$package$index_js`. Any file that then `require`s this specific file will have that `require` call replaced with the identifier.
reference.

The Babel plugin also communicates back any files that were required to make sure they are included by Sprockets. `Sprockets::Commoner` depends on the topological ordering that Sprockets does to make sure any module that is needed is instantiated before it is used.

### Example

After the regular Babel plugins are done doing their thing, `babel-plugin-commoner-internal` kicks in, which is commoner's plugin that does the actual resolving. This plugin does the following things:

* It finds any `require` calls and rewires them to variable references (as detailed in [`require` support](#require-support))
* It wraps the module in a function and supplies it with `module` and `exports`. The end value of `module.exports` gets assigned to the module identifier, which is referenced by other files (as specified in '`require` support') Example:

```
var __commoner_module__node_modules$package$index_js = __commoner_initialize_module__(function (module, exports) {
  exports.default = 123;
});
```
* If these is an expose directive at the top of the file, it assigns `module.exports` to the specified variable. For example, if the top of the file contains `'expose window.Whatever';` it will assign `exports.default` if there is a default, otherwise it just assigns `exports`. Therefore if our file has `expose window.Whatever` and no default, it will get `window.Whatever = exports;` appended to it.

#### Bundling

After all the files have been transformed, there is a bundle step which combines all of the processed JavaScript modules together. It then prepends an initializer function and all the Babel helpers (which are shared between all modules).

For example, if we have the following two files:

```
// module.js
export default function a() {
  return 1;
};
```

```
// application.js
import a from './module';

a();
```

We will end up with the following (browser-runnable) file:

```
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
};
var __commoner_module__app$assets$javascripts$module_js = __commoner_initialize_module__(function (module, exports) {
  "use strict";

  Object.defineProperty(exports, "__esModule", {
    value: true
  });
  exports.default = a;
  function a() {
    return 1;
  };
});
var __commoner_module__app$assets$javascripts$application_js = __commoner_initialize_module__(function (module, exports) {
  'use strict';

  var _module2 = __commoner_helper__interopRequireDefault(__commoner_module__app$assets$javascripts$module_js);

  (0, _module2.default)();
});
}();
```

This file is meant to be compressed, and does incredibly well when processed by UglifyJS.

