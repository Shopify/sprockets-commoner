var path = require('path');

var rootDir = path.resolve(__dirname, '../');

module.exports = {
  sourceRoot: rootDir,
  options: {
    paths: [__dirname]
  },
  expectedRequires: [__dirname + '/whatever.js']
}
