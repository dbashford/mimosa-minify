"use strict"

exports.defaults = ->
  minify:
    exclude:[/\.min\./]

exports.placeholder = ->
  """
  \t

    minify:                     # Configuration for non-require minification/compression via
                                # uglify using the --minify flag.
      exclude:[/\\.min\\./]       # List of string paths and regexes to match files to exclude
                                # when running minification. Any path with ".min." in its name,
                                # like jquery.min.js, is assumed to already be minified and is
                                # ignored by default. Paths can be relative to the
                                # watch.compiledDir, or absolute.  Paths are to compiled files,
                                # so '.js' rather than '.coffee'
  """

exports.validate = (config, validators) ->
  errors = []
  if validators.ifExistsIsObject(errors, "minify config", config.minify)
    validators.ifExistsFileExcludeWithRegexAndString(errors, "minify.exclude", config.minify, config.watch.compiledDir)

  errors
