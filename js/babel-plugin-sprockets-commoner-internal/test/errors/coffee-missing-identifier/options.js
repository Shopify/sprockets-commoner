var path = require('path');

var rootDir = path.resolve(__dirname, './');

module.exports = {
  sourceRoot: rootDir,
  error: "No identifier found in " + __dirname + "/nothing.coffee"
};
