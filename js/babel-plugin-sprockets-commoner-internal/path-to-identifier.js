// Transform a path into a variable name
module.exports = function pathToIdentifier(path) {
  var escapedPath = path.replace(/[^a-zA-Z0-9_]/g, function (match) {
    if (match === '/') {
      return '$';
    } else {
      return '_';
    }
  });
  return '__commoner_module__' + escapedPath;
};
