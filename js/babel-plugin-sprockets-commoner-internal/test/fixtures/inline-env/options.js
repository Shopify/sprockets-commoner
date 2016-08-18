var path = require('path');

var rootDir = path.resolve(__dirname, '../../../');

module.exports = {
  sourceRoot: rootDir,
  expectedIncludedEnvironmentVariables: ['NODE_ENV'],
};
