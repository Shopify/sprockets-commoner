var path    = require('path');
var fs      = require('fs');
var assert  = require('assert');
var babel   = require('@babel/core');
var plugin = require.resolve('../');

function trim(str) {
  return str.replace(/^\s+|\s+$/, '');
}

describe('babel-plugin-sprockets-commoner-internal', function() {
  function transform(aPath, sourceRoot, options) {
    var code = fs.readFileSync(aPath, 'utf8');
    const result = babel.transformSync(code, {
      filename: aPath,
      sourceRoot: sourceRoot,
      plugins: [
        [plugin, options],
      ],
    });

    return result;
  }

  var fixturesDir = path.join(__dirname, 'fixtures');

  fs.readdirSync(fixturesDir).map(function(caseName) {
    var fixtureDir = path.join(fixturesDir, caseName);

    var optionsPath = path.join(fixtureDir, 'options.js');
    var options     = require(optionsPath);

    var actualPath    = path.join(fixtureDir, 'actual.js');
    var expectedPath  = path.join(fixtureDir, 'expected.js');
    var pluginOptions = {};
    if (options.options) {
      Object.assign(pluginOptions, options.options);
    }

    var result = transform(actualPath, options.sourceRoot, pluginOptions);
    var expected = fs.readFileSync(expectedPath, 'utf8');
    it('works for the ' + caseName + ' case', function() {
      assert.equal(trim(expected), trim(result.code));
      if (options.expectedRequires != null) {
        assert.deepEqual(options.expectedRequires, result.metadata.required);
      }
      if (options.expectedTargetsToProcess != null) {
        assert.deepEqual(options.expectedTargetsToProcess, result.metadata.targetsToProcess);
      }
      if (options.expectedIncludedEnvironmentVariables) {
        assert.deepEqual(options.expectedIncludedEnvironmentVariables, result.metadata.includedEnvironmentVariables);
      }
    });
  });

  var errorsDir = path.join(__dirname, 'errors');
  
  fs.readdirSync(errorsDir).map(function(caseName) {
    var errorDir = path.join(errorsDir, caseName);

    var optionsPath = path.join(errorDir, 'options.js');
    var options     = require(optionsPath, 'utf8');

    var actualPath    = path.join(errorDir, 'actual.js');
    var pluginOptions = {};
    if (options.options) {
      Object.assign(pluginOptions, options.options);
    }
    it('works for the ' + caseName + ' case', function() {
      try {
        var result = transform(actualPath, options.sourceRoot, pluginOptions);
        assert(false);
      } catch (e) {
        assert.equal(e.message, options.error);
      }
    });
  });
});
