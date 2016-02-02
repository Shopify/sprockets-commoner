var path = require('path');

var rootDir = path.resolve(__dirname, '../../../');

module.exports = {
  options: {
    rootDir: rootDir,
  },
  expectedRequires: [
    rootDir + '/node_modules/babel-core/index.js'
  ]
};
