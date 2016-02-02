var readline = require('readline');
var rl = readline.createInterface({
  input: process.stdin,
  terminal: false,
});
var babel = require('babel-core');

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
