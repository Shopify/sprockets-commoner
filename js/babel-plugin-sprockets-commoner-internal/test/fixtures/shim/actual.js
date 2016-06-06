'use strict';

require('react/lib/ReactContext');
require('babel-core');
require('stream');

console.log(nonsense.process);

var a = process;
console.log(process.version);
console.log(a.version);
console.log(Buffer.isBuffer);

(function(process) {
  console.log(process);
})(1);
