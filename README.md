# Sprockets::BabelNode

Uses Node directly to run Babel instead of ExecJS. This gives the benefit of being able to use any Babel plugin and configuration, without depending on them being vendored into the gem.

## Methodology

BabelNode registers a postprocessor that takes any `application/javascript` data and passes it through Babel.

It works by spawning a node processes to do the actual compilation. It then sends messages back and forth to this process with code.

Potentially this plugin can also take the role of a packager like Webpack or Browserify. A proof of concept of this functionality can be found in the branch 'packager'.
