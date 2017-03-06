# Changelog

## v0.6.4

* Add support for ExecJS.

## v0.6.2

* Add support for Sprockets 4

## v0.6.1

* Ensure a file's cache is busted if it depends on an environment variable.

## v0.6.0

* Adds support for resolving files in other bundles to global variables.

## v0.5.1

* Make sure we error out if an identifier is requested from a CoffeeScript file and there is none present.

## v0.5.0

* Added (currently undocumented) `transform_options` argument to `Processor`.
* Removed undocumented babelrc configuration method.

## v0.4.0

* Added `Sprockets::Commoner::Processor.unregister` method to remove the processor.

## v0.3.0

* Added `Sprockets::Commoner::Processor.configure` method to simplify setup.

## v0.2.8

* Modified the `cache_key` method of processor to not spin up a node process, but instead read the package.json directly.

## v0.2.7

* Upgrade vendored `browser-resolve` to latest version to ensure compatibility with Node v6.

## v0.2.6

* Make sure we don't rename a bound file if the same file is required multiple times. Fixes [#19](https://github.com/Shopify/sprockets-commoner/issues/19).

## v0.2.5

* Add `cache_key` to processor to make sure we bust the cache when processor config changes.

## v0.2.4

* Enable completely optimizing away empty module definitions.

## v0.2.3

* Only avoid imports that won't be processed by Commoner if we actually use the module.

## v0.2.2

* Don't cache Babel output as this can lead to bugs.
* Avoid imports of files that won't be processed by Commoner, to defend against bugs.
* Exclude vendor/bundle by default.

## v0.2.1

* Fix bug with `browser` field stubbing out modules.
* Add support for requiring CoffeeScript files that don't define any globals.

## v0.2.0

* Add support for requiring JSON files.

## v0.1.3

* Backport fixes from v0.2.3

## v0.1.2

* Backport fixes from v0.2.2

## v0.1.1

* Backport fixes from v0.2.1.

## v0.1.0

* Initial version.
