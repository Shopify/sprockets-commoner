# babel-plugin-rewire-require

## Usage

`babel-plugin-rewire-require` accepts the following options:

* `rootDir` the directory where all modules should be under. If a module is required outside rootDir, an error is thrown. This option also makes all the paths emitted in require functions relative to the directory.
* Any of the options specified in [resolve](https://github.com/substack/node-resolve#resolvesyncid-opts).

### Via `.babelrc` (Recommended)

**.babelrc**

```json
{
  "plugins": [["rewire-require", {"extensions": [".js", ".json", ".es6"]}]]
}
```

### Via CLI

```sh
$ babel --plugins rewire-require script.js
```

### Via Node API

```javascript
require("babel-core").transform("code", {
  plugins: ["rewire-require"]
});
```
