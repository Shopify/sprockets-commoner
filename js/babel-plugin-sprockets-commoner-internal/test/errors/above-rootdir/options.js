var path = require('path');

var rootDir = path.resolve(__dirname, '../');

module.exports = {
  sourceRoot: rootDir,
  error: "Cannot find module '@babel/core' from '" + __dirname + "' under '" + rootDir + "'"
};
