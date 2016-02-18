var path = require('path');

var rootDir = path.resolve(__dirname, './');

module.exports = {
  sourceRoot: rootDir,
  expectedRequires: [
    rootDir + '/class.coffee',
    rootDir + '/assign.coffee'
  ]
};
