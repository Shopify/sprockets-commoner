# Sprockets::BabelNode

Uses Node directly to run Babel instead of ExecJS. This gives the benefit of being able to use any Babel plugin and configuration, without depending on them being vendored into the gem.

## Methodology

BabelNode registers a postprocessor that takes any `application/javascript` file and passes it through Babel.

BabelNode will work its magic on any JavaScript file that has a `.babelrc` somewhere in its tree.

It works by spawning a node process to do the actual translation. It then sends messages back and forth to this process with code. The reason it uses a Node process instead of ExecJS is because ExecJS has a lot less flexibility in allowing a JavaScript backend to specify its environment, so they can't do things like `require` outside packages. This means that any gem that uses it has to vendor in all the JavaScript dependencies, which is what `sprockets-es6` does.

### `require` support

`Sprockets::BabelNode` supports `require()` by replacing `require` function calls with variable references. It does this by assigning every file a unique identifier based on their filename. For example, if the file you're referencing is located at `<root>/node_modules/package/index.js` it will get the name `__babel_node_module__node_modules$package$index_js`. Any file that then `require`s this specific file will have that `require` call replaced with the identifier.

If the resolved file is a CoffeeScript file however, it needs to do another trick. The resolving step will execute a RegExp against the file to find any global variable definitions inside the file, and will replace the `require` call with a global variable reference.

The Babel plugin also communicates back any files that were required to make sure they are included by Sprockets. `Sprockets::BabelNode` depends on the topological ordering that Sprockets does to make sure any module that is needed is instantiated before it is used.

## Steps

`Sprockets::BabelNode` works in a couple of steps. When the processor starts up it spins off a Node.js process in the root directory of the Sprockets environment (which is `Rails.root` in a Rails app). This is also where you should install `babel-core` to make sure the process has access to it. `Sprockets::BabelNode` doesn't include Babel, so you need to install this yourself.

### Step 1

First the file is passed through any Babel plugins that are defined in your `.babelrc`. You shouldn't include `babel-plugin-transform-es2015-modules-commonjs` because the  internal Babel plugin in `Sprockets::BabelNode` does this already.

### Step 2

After the regular Babel plugins are done doing their thing, `babel-plugin-rewire-require` kicks in, which is Sprockets' internal plugin. This plugin does the following things:

* It finds any `require` calls and rewires them to variable references (as detailed in [`require` support](#require-support))
* It wraps the module in a function and supplies it with `module` and `exports`. The end value of `module.exports` gets assigned to the module identifier, which is referenced by other files (as specified in '`require` support') Example:

```
var __babel_node_module__node_modules$package$index_js = __babel_node_initialize_module__(function (module, exports) {
  exports.default = 123;
});
```
* If these is an expose directive at the top of the file, it assigns `module.exports` to the specified variable. For example, if the top of the file contains `'expose window.Whatever';` it will assign `exports.default` if there is a default, otherwise it just assigns `exports`. Therefore if our file has `expose window.Whatever` and no default, it will get `window.Whatever = exports;` appended to it.

### Step 3

After all the files have been transformed, there is a bundle step which combines them all together. There is also a prefix that gets added to the file, which contains the `__babel_node_initialize_module__` function. This is very simple function and looks like this:

```
var __babel_node_initialize_module__ = function(f) {
  var module = {exports: {}};
  f.call(module.exports, module, module.exports);
  return module.exports;
};
```

It just sets up a namespace for a module and then calls it.


## Known things

* Stubbing doesn't work. It does its thing, but the plugin is not aware that a file will not be included, so any module that imports that file . Ideally we could have some sort of way to import libraries in one file and have them exported to the global object, and then be able to use the knowledge of which files are exported in this way to reference those in another file. For now you need to use the `globals` option to manually fill in any dependencies you know are being stubbed.

* We can optimise `typeof module === "object" && typeof module.exports === "object"` to make UMD (like jQuery, React, basically any big JS library) slightly smaller.
