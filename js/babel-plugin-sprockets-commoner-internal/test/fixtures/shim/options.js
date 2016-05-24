var path = require('path');

var rootDir = path.resolve(__dirname, '../../../');

module.exports = {
  sourceRoot: rootDir,
  expectedRequires: [
    rootDir + '/node_modules/babel-core/index.js',
    rootDir + '/node_modules/stream-browserify/index.js',
    rootDir + '/node_modules/process/browser.js',
    rootDir + '/node_modules/process/browser.js',
    rootDir + '/node_modules/buffer/index.js',
  ],
  options: {
    moduleShim: {
      'react/lib/ReactContext': false,
      'whatever': 'babel-core'
    }
  }
};
