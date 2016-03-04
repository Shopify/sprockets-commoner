var a = require('./a');

exports.f = function() {
  return a.value;
}
exports.value = 2;
