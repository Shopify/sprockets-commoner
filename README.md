# Sprockets::BabelNode

Uses Node directly to run Babel instead of ExecJS. This gives the benefit of being able to use any Babel plugin and configuration, without depending on them being vendored into the gem.

## Methodology

BabelNode adds an internal mimetype called `babel-node/commonjs-artifact` that it uses to coordinate compilation of es6 modules to JavaScript.

It works by spawning a node processes to do the actual compilation. It then sends messages back and forth to this process with code.

BabelNode uses a babel plugin `babel-plugin-rewire-require` which is included in this repo. This plugin finds any call to `require` and converts them to variable references. It also reports back which files were required, so Sprockets can take care of including those in the bundle. It resolves the correct path of the required files using [node-resolve](https://github.com/substack/node-resolve).

This way any es6 files are converted to commonjs using the standard babel plugin. If a regular JavaScript file is `import`ed, BabelNode will also convert that file to a commonjs module and find any other `require` calls inside the result, and so on.

## Known Issues

1. A file can be both `//= require`d and imported at the same time, leading to code duplication.
