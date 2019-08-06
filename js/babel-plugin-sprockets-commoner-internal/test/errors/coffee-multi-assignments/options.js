var path = require('path');

var rootDir = path.resolve(__dirname, './');

module.exports = {
  sourceRoot: rootDir,
  error: "Multiple identifiers found in " + __dirname + "/multi.coffee"
};
