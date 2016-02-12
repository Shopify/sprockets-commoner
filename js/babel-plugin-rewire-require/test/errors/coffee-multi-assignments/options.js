var path = require('path');

var rootDir = path.resolve(__dirname, './');

module.exports = {
  sourceRoot: rootDir,
  error: __dirname + "/actual.js: Multiple identifiers found in " + __dirname + "/multi.coffee"
};
