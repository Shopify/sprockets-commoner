'use strict';
if (typeof Object.assign != 'function') {
  (function () {
    Object.assign = function (target) {
      'use strict';
      if (target === undefined || target === null) {
        throw new TypeError('Cannot convert undefined or null to object');
      }

      var output = Object(target);
      for (var index = 1; index < arguments.length; index++) {
        var source = arguments[index];
        if (source !== undefined && source !== null) {
          for (var nextKey in source) {
            if (source.hasOwnProperty(nextKey)) {
              output[nextKey] = source[nextKey];
            }
          }
        }
      }
      return output;
    };
  })();
}

var fs = require('fs');
var dirname = require('path').dirname;
var resolve = require('browser-resolve').sync;

module.exports = function (context) {
  var t = context.types;
  var exposeTemplate = context.template("$0 = exports['default'] != null ? exports['default'] : exports;");

  var opts = null;
  var rootRegex = null;
  var identifierRegex = null;

  function createIdentifierRegex() {
    var globals = ['window'].concat(opts.globalNamespaces).map(function(namespace) {
      return namespace + '\\.';
    });

    // Construct regex with prefixes which denote globals (like window.Something, @Something, or anything else in opts.globalNamespaces)
    var globalObject = '(?:@|' + globals.join('|') + ')';
    var validIdentifier = '[a-zA-Z][_a-zA-Z0-9]*';
    // Look for identifiers that look like 'window.Something' or 'Shopify.Something'
    var validAssignment = '(' + globalObject + validIdentifier + '(?:\\.' + validIdentifier + ')*)';
    // Look for 'window.Something =' or 'class window.Something'
    return '^(?:(?:' + validAssignment + '\\s*=)|(?:class ' + validAssignment + '))';
  }

  /*
   * BIGGEST HACK OF __ALL_TIME__
   * If we're requiring a CoffeeScript file, we're going to be assuming that we're assigning to the global namespace in that file.
   * so, use a RegExp to find out that variable definition. (yep)
   */
  function findDeclarationInCoffeeFile(path) {
    var contents = fs.readFileSync(path);
    var identifiers = [];

    for (var regexp = new RegExp(identifierRegex, 'gm'), find = regexp.exec(contents); find != null; find = regexp.exec(contents)) {
      identifiers.push(find[1] || find[2]);
    }

    if (identifiers.length === 0) {
      return false;
    } else if (identifiers.length > 1) {
      throw new Error('Multiple identifiers found in ' + path);
    }

    return identifiers[0].replace(/^@/, 'window.');
  }

  function isRequire(path) {
    return path.isCallExpression() && path.get('callee').isIdentifier({ name: 'require' }) && !path.scope.hasBinding('require');
  }

  // Get the target path from a require call
  function requireTarget(path) {
    var evaluate = path.get('arguments')[0].evaluate();
    if (!evaluate.confident || path.node.arguments.length !== 1) {
      return null;
    }

    var target = evaluate.value;
    if (typeof target !== 'string') {
      throw new Error('Invalid require call, string expected');
    }
    return target;
  }

  // Find any 'expose <name>' directive and get back the value of '<name>'
  function findExpose(directives) {
    var result = void 0;
    for (var i = 0; i < directives.length; i++) {
      if (result = /^expose ([A-Za-z\.]+)$/.exec(directives[i].value.value)) {
        directives.splice(i, 1);
        return result[1];
      }
    }
    return null;
  }


  // Transform a path into a variable name
  function pathToIdentifier(path) {
    var escapedPath = path.replace(rootRegex, '').replace(/[^a-zA-Z0-9_]/g, function (match) {
      if (match === '/') {
        return '$';
      } else {
        return '_';
      }
    });
    return '__commoner_module__' + escapedPath;
  }

  function resolveTarget(file, path) {
    var name = void 0;
    if (opts.globals != null && (name = opts.globals[path]) != null) {
      return name;
    } else {
      var resolvedPath = resolve(path, opts);
      file.metadata.required.push(resolvedPath);

      // Check if the path is under sourceRoot
      var root = file.opts.sourceRoot;
      if (!rootRegex.test(resolvedPath)) {
        throw new Error("Cannot find module '" + path + "' from '" + dirname(file.opts.filename) + "' under '" + root + "'");
      }

      if (/\.coffee$/.test(resolvedPath)) {
        // If it's a coffee script file, look for global variable assignments
        return findDeclarationInCoffeeFile(resolvedPath);
      } else {
        // Otherwise we just look for the module by referencing its Special Identifier™
        return pathToIdentifier(resolvedPath);
      }
    }
  }

  var callRewriter = {
    VariableDeclarator: function VariableDeclarator(path, state) {
      var init = path.get('init');
      if (!isRequire(init)) {
        return;
      }
      var binding = path.scope.getBinding(path.node.id.name);
      if (!binding.constant) {
        return;
      }

      var target = requireTarget(init);
      if (target == null) {
        return;
      }

      var name = resolveTarget(state.file, target);
      path.scope.rename(name);
      path.scope.rename(path.node.id.name, name);
      path.remove();
    },
    CallExpression: function CallExpression(path, state) {
      if (!isRequire(path)) {
        return;
      }

      var target = requireTarget(path);
      if (target == null) {
        return;
      }

      var replacement = resolveTarget(state.file, target);
      switch (path.parent.type) {
        case "ExpressionStatement":
          // We just need to know there's a dependency, we can remove it then
          path.remove();
          break;
        default:
          // Otherwise we just look for the module by referencing its Special Identifier™
          path.replaceWith(t.identifier(replacement));
          break;
      }
    }
  };

  return {
    pre: function pre(file) {
      if (file.metadata.required == null) {
        file.metadata.required = [];
      }
    },

    visitor: {
      MemberExpression: function MemberExpression(path) {
        if (path.get("object").matchesPattern("process.env")) {
          var key = path.toComputedKey();
          if (t.isStringLiteral(key)) {
            path.replaceWith(t.valueToNode(process.env[key.value]));
          }
        }
      },
      UnaryExpression: function UnaryExpression(path) {
        if (!path.node.operator === 'typeof') {
          return;
        }

        var argument = path.get('argument');
        if (!path.get('argument').isIdentifier()) {
          return;
        }

        var name = path.node.argument.name;
        if (name !== 'module' && name !== 'exports') {
          return;
        }

        if (path.scope.hasBinding(name)) {
          return;
        }

        path.replaceWith(t.stringLiteral('object'));
      },
      Program: {
        exit: function exit(path, state) {
          // Get options from commoner-options and merge them with the options
          // that were passed to this plugin in .babelrc
          opts = {
            globalNamespaces: [],
            // We can get these from Sprockets
            extensions: ['.js', '.json', '.coffee', '.js.erb', '.coffee.erb']
          };

          // Look for the sprockets-commoner plugin for extra options
          state.file.opts.plugins.map(function (plugin) {
            return plugin[1];
          }).filter(function (opts) {
            return opts != null && opts.__commoner_options;
          }).forEach(function (plugin) {
            return Object.assign(opts, plugin);
          });

          Object.assign(opts, state.opts, { basedir: dirname(state.file.opts.filename) });
          rootRegex = new RegExp('^' + state.file.opts.sourceRoot + '/');
          identifierRegex = createIdentifierRegex();

          // Signal back to Sprockets that we're rewiring
          state.file.metadata.commonerEnabled = true;

          var node = path.node;
          var identifier = pathToIdentifier(state.file.opts.filename);
          var expose = findExpose(node.directives);
          if (expose != null) {
            node.body.push(exposeTemplate(t.identifier(expose)));
          }

          // Transform module to a variable assignment.
          // This variable is then referenced by any dependant children.
          node.body = [t.variableDeclaration('var', [t.variableDeclarator(t.identifier(identifier), t.callExpression(t.identifier('__commoner_initialize_module__'), [t.functionExpression(null, [t.identifier('module'), t.identifier('exports')], t.blockStatement(node.body, node.directives))]))])];
          node.directives = [];
          path.traverse(callRewriter, state);
        }
      }
    }
  };
};
