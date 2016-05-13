# Changelog

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
