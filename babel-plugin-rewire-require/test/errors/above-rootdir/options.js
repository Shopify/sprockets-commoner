var path = require('path');

var rootDir = path.resolve(__dirname, '../../');

module.exports = {
  options: {
    rootDir: rootDir,
  },
  error: __dirname + "/actual.js: Cannot find module 'babel-cli' from '" + __dirname + "'"
};
