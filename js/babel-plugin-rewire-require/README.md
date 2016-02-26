# babel-plugin-rewire-require

## Usage

`babel-plugin-rewire-require` should be included in your `.babelrc` by adding `rewire-require`. You can't install it through npm, but this directory is automatically added to the path by the Sprockets plugin.

## Options

* `globals`: A mapping of module name to global variable name, which will ovveride any import of that package with a global variable reference.

## Example

```json
{
  presets: ["es2015"],
  plugins: [
    ["rewire-require", {
      globals: {
        "jquery": "$"
      }
    }]
  ]
}
```
