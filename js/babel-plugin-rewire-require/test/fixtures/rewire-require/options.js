var path = require('path');

var rootDir = path.resolve(__dirname, '../../../');

module.exports = {
  sourceRoot: rootDir,
  expectedRequires: [
    rootDir + '/node_modules/babel-core/index.js'
  ]
};
