var path = require('path');

var rootDir = path.resolve(__dirname, '../');

module.exports = {
  sourceRoot: rootDir,
  expectedRequires: [__dirname + '/whatever.js']
}
