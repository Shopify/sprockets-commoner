var path    = require('path');
var fs      = require('fs');
var assert  = require('assert');
var babel   = require('babel-core');
var plugin  = require('../')

function trim(str) {
  return str.replace(/^\s+|\s+$/, '');
}

describe('babel-plugin-transform-dev', function() {
  var fixturesDir = path.join(__dirname, 'fixtures');

  fs.readdirSync(fixturesDir).map(function(caseName) {
    var fixtureDir = path.join(fixturesDir, caseName);

    var optionsPath = path.join(fixtureDir, 'options.js');
    var options     = require(optionsPath, 'utf8');

    var actualPath    = path.join(fixtureDir, 'actual.js');
    var expectedPath  = path.join(fixtureDir, 'expected.js');

    var babelOptions = { plugins: [ [plugin, options.options] ], metadata: true };

    var result = babel.transformFileSync(actualPath, babelOptions);
    var actual = result.code;
    var expected  = fs.readFileSync(expectedPath, 'utf8');

    it('works for the ' + caseName + ' case', function() {
      assert.equal(trim(actual), trim(expected));
      if (options.expectedRequires != null) {
        assert.deepEqual(options.expectedRequires, result.metadata.requires);
      }
    });
  });

  var errorsDir = path.join(__dirname, 'errors');

  fs.readdirSync(errorsDir).map(function(caseName) {
    var errorDir = path.join(errorsDir, caseName);

    var optionsPath = path.join(errorDir, 'options.js');
    var options     = require(optionsPath, 'utf8');

    var actualPath    = path.join(errorDir, 'actual.js');
    var babelOptions = { plugins: [ [plugin, options.options] ], metadata: true };


    it('works for the ' + caseName + ' case', function() {
      try {
        var result = babel.transformFileSync(actualPath, babelOptions);
        assert(false);
      } catch (e) {
        assert.equal(e.message, options.error);
      }
    });
  });
});
