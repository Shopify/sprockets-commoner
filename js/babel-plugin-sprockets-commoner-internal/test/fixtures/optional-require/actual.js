try {
  var exists = require('./doesnt-exist.js');
  console.log(exists);
} catch (err) {
  var exists = require('./exists.js');
  console.log(exists);
}
console.log(exists);
