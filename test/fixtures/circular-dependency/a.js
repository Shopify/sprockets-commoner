var b = require('./b');

exports.f = function() {
  return b.value;
}
exports.value = 1;
