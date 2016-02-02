var resolve = require('./vendor/resolve').sync;
var dirname = require('path').dirname;

function escapePath(path) {
  return path.replace(/[^a-zA-Z0-9_]/g, function(match) {
    if (match === '/') {
      return '$';
    } else {
      return '_';
    }
  });
}

module.exports.__esModule = true;
module.exports.default = function(opts) {
  var t = opts.types;
  return {
    visitor: {
      CallExpression: function(path, state) {
        if (path.get("callee").isIdentifier({name: "require"}) && path.node.arguments.length === 1) {
          var evaluate = path.get("arguments")[0].evaluate();
          if (!evaluate.confident) return;

          var target = evaluate.value;
          if (typeof target !== "string") return;

          var file = state.file;
          var basedir = dirname(file.opts.filename);
          var opts = {extensions: ['.js', '.json']};
          for (var key in state.opts) {
            opts[key] = state.opts[key];
          }
          opts.basedir = basedir;
          var resolved = resolve(target, opts);

          if (file.metadata.requires == null) {
            file.metadata.requires = [];
          }
          file.metadata.requires.push(resolved);

          var root = state.opts.rootDir;
          if (root != null) {
            if (root[root.length - 1] !== '/') {
              root += '/';
            }
            if (resolved.substring(0, root.length) !== root) {
              throw new Error("Cannot find module '" + target + "' from '" + basedir + "'");
            }
            resolved = resolved.substring(root.length);
          }
          path.replaceWithSourceString('__babel_node_module__' + escapePath(resolved));
        }
      }
    }
  };
};
