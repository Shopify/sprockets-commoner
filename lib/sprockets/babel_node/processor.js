var readline = require('readline');
var rl = readline.createInterface({
  input: process.stdin,
  terminal: false,
});
var babel = require('babel-core');
var helpers = require('babel-helpers');
var t = require('babel-types');
var generator = require('babel-generator').default;

var methods = {
  version: function() {
    return {
      nodeVersion: process.version,
      babelVersion: babel.version,
    };
  },
  transform: function(opts) {
    return babel.transform(opts['data'], opts['options']);
  },
  helpers: function(opts) {
    var declaration = t.variableDeclaration('var',
      opts.helpers.map(function(helper) {
        return t.variableDeclarator(t.identifier('__babel_node_helper__' + helper), helpers.get(helper));
      })
    );
    return {
      code: generator(declaration).code
    };
  }
};

rl.on('line', function(line) {
  var input = JSON.parse(line);
  var output;
  try {
    output = ['ok', methods[input.method](input)];
  } catch (e) {
    output = ['err', e.toString()];
  }
  process.stdout.write(JSON.stringify(output));
  process.stdout.write('\n');
});
