var fs = require('fs');
var resolve = require('./vendor/resolve').sync;
var dirname = require('path').dirname;

var GLOBAL_OBJECT = '(?:window|Shopify)';
var VALID_IDENTIFIER = '[a-zA-Z][_a-zA-Z0-9_]*';
// Look for identifiers that look like 'window.Something' or 'Shopify.Something'
var VALID_ASSIGNMENT = '(' + GLOBAL_OBJECT + '(?:\\.' + VALID_IDENTIFIER + ')+)';
// Look for 'window.Something =' or 'class window.Something'
var IDENTIFIER_REGEX = '^(?:(?:' + VALID_ASSIGNMENT + '\\s*=)|(?:class ' + VALID_ASSIGNMENT + '))';

function escapePath(path) {
  return '__babel_node_module__' + path.replace(/[^a-zA-Z0-9_]/g, function(match) {
    if (match === '/') {
      return '$';
    } else {
      return '_';
    }
  });
}

function getOpts(state) {
  var opts = {
    /* TODO(bouk): Could we get this info from Sprockets somehow?
     * We could also just re-implement the resolve algorithm in Ruby and do this in Ruby land.
     * (Incomplete) prototype: https://gist.github.com/bouk/5d833ceb5e7e08e01dd8
     * We'd have no way of knowing the final module identifier though.
     *
     * Best is probably just to ask Sprockets what extensions it can convert into application/javascript
     */
    extensions: [
      '.js',
      '.json',
      '.coffee'
      '.js.erb',
      '.coffee.erb'
    ],
    /* TODO(bouk): This should be the Sprockets paths.
     * We then also need to make sure that whatever it resolves to is inside any of the paths.
     */
    paths: [state.file.opts.sourceRoot]
  };
  for (var key in state.opts) {
    opts[key] = state.opts[key];
  }
  opts.basedir = dirname(state.file.opts.filename);
  return opts;
}

function addRequire(state, path) {
  var metadata = state.file.metadata;
  if (metadata.requires == null) {
    metadata.requires = [];
  }
  metadata.requires.push(path);
}

function rootRegex(state) {
  var sourceRoot = state.file.opts.sourceRoot;
  return sourceRoot && new RegExp('^' + sourceRoot + '/');
}

// Transform a path into a variable name
function pathToIdentifier(regex, path) {
  if (regex == null) {
    return escapePath(path);
  } else {
    return escapePath(path.replace(regex, ''));
  }
}

// Use RegExp to find global variable assignment in CoffeeScript file
function findDeclarationInCoffeeFile(path) {
  var contents = fs.readFileSync(path);
  var identifiers = [];

  for (
  var regexp = new RegExp(IDENTIFIER_REGEX, 'gm'),
    find = regexp.exec(contents);
  find != null;
  find = regexp.exec(contents)) {
    identifiers.push(find[1] || find[2]);
  }

  if (identifiers.length === 0) {
    throw new Error("No identifiers found in " + path);
  } else if (identifiers.length > 1) {
    throw new Error("Multiple identifiers found in " + path);
  }

  return identifiers[0];
}

// Get the target path from a require call
function requireTarget(path) {
  var evaluate = path.get('arguments')[0].evaluate();
  if (!evaluate.confident || path.node.arguments.length !== 1) {
    throw new Error('Dynamic require calls not supported');
  }

  var target = evaluate.value;
  if (typeof target !== 'string') {
    throw new Error('Invalid require call, string expected');
  }
  return target;
}

// Find any 'expose <name>' directive and get back the value of '<name>'
function findExpose(directives) {
  var result;
  for (var i = 0; i < directives.length; i++) {
    if (result = /^expose ([A-Za-z\.]+)$/.exec(directives[i].value.value)) {
      directives.splice(i, 1);
      return result[1];
    }
  }
  return null;
}

var exposeTemplate = null;

module.exports.__esModule = true;
module.exports.default = function(context) {
  var t = context.types;
  if (exposeTemplate == null) {
    exposeTemplate = context.template("$0 = exports['default'] != null ? exports['default'] : exports;");
  }

  var callRewriter = {
    CallExpression: function(path, state) {
      if (path.get('callee').isIdentifier({name: 'require'})) {
        var target = requireTarget(path);
        var opts = getOpts(state);

        if (opts.globals != null && opts.globals[target] != null) {
          path.replaceWithSourceString(opts.globals[target]);
          return;
        }

        var regex = rootRegex(state);
        var resolvedFile = resolve(target, opts);
        var root = state.file.opts.sourceRoot;
        // Check if the path is under sourceRoot
        if (!regex.test(resolvedFile)) {
          throw new Error("Cannot find module '" + target + "' from '" + dirname(state.file.opts.filename) + "' under '" + root + "'");
        }
        addRequire(state, resolvedFile);

        /*
         * BIGGEST HACK OF __ALL_TIME__
         * If we're requiring a CoffeeScript file, we're going to be assuming that we're assigning to the global namespace in that file.
         * so, use a RegExp to find out that variable definition. (yep)
         *
         * We can remove this once all CoffeeScript is gone
         */
        if (/\.coffee$/.test(resolvedFile)) {
          var identifier = findDeclarationInCoffeeFile(resolvedFile);
          path.replaceWithSourceString(identifier);
        } else {
          // Otherwise we just look for the module by referencing its Special Identifier™
          path.replaceWith(t.identifier(pathToIdentifier(regex, resolvedFile)));
        }
      }
    }
  };

  return {
    inherits: require(resolve('babel-plugin-transform-es2015-modules-commonjs', {basedir: process.cwd()})),
    pre: function(file) {
      file.set("helperGenerator", function (name) {
        // The actual helpers are generated in babel.rb
        return t.identifier('__babel_node_helper__' + name);
      });
    },
    visitor: {
      Program: {
        exit: function(path, state) {
          state.file.metadata.rewireRequireEnabled = true;
          var node = path.node;
          var regex = rootRegex(state);
          var identifier = pathToIdentifier(regex, state.file.opts.filename);
          var expose = findExpose(node.directives);
          if (expose != null) {
            node.body.push(exposeTemplate(t.identifier(expose)));
          }

          // Transform module to a variable assignment.
          // This variable is then referenced by any dependant children.
          node.body = [t.variableDeclaration(
            'var',
            [t.variableDeclarator(
              t.identifier(identifier),
              t.callExpression(
                t.identifier('__babel_node_initialize_module__'),
                [t.functionExpression(
                  null,
                  [t.identifier('module'), t.identifier('exports')],
                  t.blockStatement(node.body, node.directives)
                )]
              )
            )]
          )];
          node.directives = [];
          path.traverse(callRewriter, state);
        }
      }
    }
  };
};
