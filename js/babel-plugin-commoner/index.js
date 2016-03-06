'use strict';

const fs = require('fs');
const resolve = require('./vendor/resolve').sync;
const dirname = require('path').dirname;

const GLOBAL_OBJECT = '(?:window|Shopify|Sello)';
const VALID_IDENTIFIER = '[a-zA-Z][_a-zA-Z0-9_]*';
// Look for identifiers that look like 'window.Something' or 'Shopify.Something'
const VALID_ASSIGNMENT = `(${GLOBAL_OBJECT}(?:\\.${VALID_IDENTIFIER})+)`;
// Look for 'window.Something =' or 'class window.Something'
const IDENTIFIER_REGEX = `^(?:(?:${VALID_ASSIGNMENT}\\s*=)|(?:class ${VALID_ASSIGNMENT}))`;

/*
 * BIGGEST HACK OF __ALL_TIME__
 * If we're requiring a CoffeeScript file, we're going to be assuming that we're assigning to the global namespace in that file.
 * so, use a RegExp to find out that constiable definition. (yep)
 *
 * We can remove this once all CoffeeScript is gone
 */
 function findDeclarationInCoffeeFile(path) {
  const contents = fs.readFileSync(path);
  const identifiers = [];

  for (
  let regexp = new RegExp(IDENTIFIER_REGEX, 'gm'),
    find = regexp.exec(contents);
  find != null;
  find = regexp.exec(contents)) {
    identifiers.push(find[1] || find[2]);
  }

  if (identifiers.length === 0) {
    throw new Error(`No identifiers found in ${path}`);
  } else if (identifiers.length > 1) {
    throw new Error(`Multiple identifiers found in ${path}`);
  }

  return identifiers[0];
}

function isRequire(path) {
  return path.isCallExpression() && path.get('callee').isIdentifier({name: 'require'});
}

// Get the target path from a require call
function requireTarget(path) {
  const evaluate = path.get('arguments')[0].evaluate();
  if (!evaluate.confident || path.node.arguments.length !== 1) {
    return null;
  }

  const target = evaluate.value;
  if (typeof target !== 'string') {
    throw new Error('Invalid require call, string expected');
  }
  return target;
}

// Find any 'expose <name>' directive and get back the value of '<name>'
function findExpose(directives) {
  let result;
  for (let i = 0; i < directives.length; i++) {
    if (result = /^expose ([A-Za-z\.]+)$/.exec(directives[i].value.value)) {
      directives.splice(i, 1);
      return result[1];
    }
  }
  return null;
}

module.exports = (context) => {
  const t = context.types;
  const exposeTemplate = context.template(`$0 = exports['default'] != null ? exports['default'] : exports;`);

  let opts = null;
  let regex = null;

  // Transform a path into a variable name
  function pathToIdentifier(path) {
    const escapedPath = path.replace(regex, '').replace(/[^a-zA-Z0-9_]/g, function(match) {
      if (match === '/') {
        return '$';
      } else {
        return '_';
      }
    });
    return `__commoner_module__${escapedPath}`;
  }

  function resolveTarget(file, path) {
    let name;
    if (opts.globals != null && (name = opts.globals[path]) != null) {
      return name;
    } else {
      const resolvedPath = resolve(path, opts);
      file.metadata.requires.push(resolvedPath);

      // Check if the path is under sourceRoot
      const root = file.opts.sourceRoot;
      if (!regex.test(resolvedPath)) {
        throw new Error(`Cannot find module '${path}' from '${dirname(file.opts.filename)}' under '${root}'`);
      }

      if (/\.coffee$/.test(resolvedPath)) {
        // If it's a coffee script file, look for global variable assignments
        return findDeclarationInCoffeeFile(resolvedPath);
      } else {
        // Otherwise we just look for the module by referencing its Special Identifier™
        return pathToIdentifier(resolvedPath)
      }
    }
  }

  const callRewriter = {
    VariableDeclarator: function(path, state) {
      const init = path.get('init');
      if (!isRequire(init)) {
        return
      }
      const binding = path.scope.getBinding(path.node.id.name);
      if (!binding.constant) {
        return
      }

      const target = requireTarget(init);
      if (target == null) {
        return;
      }

      const name = resolveTarget(state.file, target);
      path.scope.rename(name);
      path.scope.rename(path.node.id.name, name);
      path.remove();
    },
    CallExpression: function(path, state) {
      if (!isRequire(path)) {
        return;
      }

      const target = requireTarget(path);
      if (target == null) {
        return;
      }

      const replacement = resolveTarget(state.file, target);
      switch(path.parent.type) {
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
    inherits: require(resolve('babel-plugin-transform-es2015-modules-commonjs', {basedir: process.cwd()})),
    pre(file) {
      if (file.metadata.requires == null) {
        file.metadata.requires = [];
      }
      // The actual helpers are generated in babel.rb
      file.set("helperGenerator", (name) => t.identifier(`__commoner_helper__${name}`));
    },
    visitor: {
      Program: {
        exit(path, state) {
          // Get options from commoner-options and merge them with the options
          // that were passed to this plugin in .babelrc
          opts = Object.assign(
            {
              // We can get these from Sprockets
              extensions: [
                '.js',
                '.json',
                '.coffee',
                '.js.erb',
                '.coffee.erb'
              ],
            },
            state.opts,
            ...state.file.opts.plugins
              .map((plugin) => plugin[1])
              .filter((opts) => opts != null && opts.__commoner_options)
          );
          opts.basedir = dirname(state.file.opts.filename);
          regex = new RegExp(`^${state.file.opts.sourceRoot}/`);

          // Signal back to Sprockets that we're rewiring
          state.file.metadata.commonerEnabled = true;

          const node = path.node;
          const identifier = pathToIdentifier(state.file.opts.filename);
          const expose = findExpose(node.directives);
          if (expose != null) {
            node.body.push(exposeTemplate(t.identifier(expose)));
          }

          // Transform module to a constiable assignment.
          // This constiable is then referenced by any dependant children.
          node.body = [t.variableDeclaration(
            'var',
            [t.variableDeclarator(
              t.identifier(identifier),
              t.callExpression(
                t.identifier('__commoner_initialize_module__'),
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
