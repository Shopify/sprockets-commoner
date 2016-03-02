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

function escapePath(path) {
  let escapedPath = path.replace(/[^a-zA-Z0-9_]/g, function(match) {
    if (match === '/') {
      return '$';
    } else {
      return '_';
    }
  });
  return `__commoner_module__${escapedPath}`;
}

function addRequire(state, path) {
  const metadata = state.file.metadata;
  if (metadata.requires == null) {
    metadata.requires = [];
  }
  metadata.requires.push(path);
}

function rootRegex(state) {
  const sourceRoot = state.file.opts.sourceRoot;
  return sourceRoot && new RegExp(`^${sourceRoot}/`);
}

// Transform a path into a constiable name
function pathToIdentifier(regex, path) {
  return escapePath(path.replace(regex, ''));
}

// Use RegExp to find global constiable assignment in CoffeeScript file
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

// Get the target path from a require call
function requireTarget(path) {
  const evaluate = path.get('arguments')[0].evaluate();
  if (!evaluate.confident || path.node.arguments.length !== 1) {
    throw new Error('Dynamic require calls not supported');
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

  const callRewriter = {
    CallExpression: function(path, state) {
      if (path.get('callee').isIdentifier({name: 'require'})) {
        const target = requireTarget(path);
        if (opts.globals != null && opts.globals[target] != null) {
          path.replaceWithSourceString(opts.globals[target]);
          return;
        }

        const regex = rootRegex(state);
        const resolvedFile = resolve(target, opts);
        const root = state.file.opts.sourceRoot;
        // Check if the path is under sourceRoot
        if (!regex.test(resolvedFile)) {
          throw new Error(`Cannot find module '${target}' from '${dirname(state.file.opts.filename)}' under '${root}'`);
        }
        addRequire(state, resolvedFile);

        /*
         * BIGGEST HACK OF __ALL_TIME__
         * If we're requiring a CoffeeScript file, we're going to be assuming that we're assigning to the global namespace in that file.
         * so, use a RegExp to find out that constiable definition. (yep)
         *
         * We can remove this once all CoffeeScript is gone
         */
        if (/\.coffee$/.test(resolvedFile)) {
          const identifier = findDeclarationInCoffeeFile(resolvedFile);
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
    pre(file) {
      // The actual helpers are generated in babel.rb
      file.set("helperGenerator", (name) => t.identifier(`__commoner_helper__${name}`));
    },
    visitor: {
      Program: {
        exit(path, state) {
          // Get options from rewire-require-options and merge them with the options
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
              .filter((opts) => opts != null && opts.__rewire_require_options)
          );
          opts.basedir = dirname(state.file.opts.filename);

          // Find rewire-require-options and copy its options into ours
          // Signal back to Sprockets that we're rewiring
          state.file.metadata.rewireRequireEnabled = true;

          const node = path.node;
          const regex = rootRegex(state);
          const identifier = pathToIdentifier(regex, state.file.opts.filename);
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
