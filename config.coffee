"use strict"

path = require 'path'

windowsDrive = /^[A-Za-z]:\\/

exports.defaults = ->
  minify:
    exclude:[/\.min\./]

exports.placeholder = ->
  """
  \t

    # minify:                     # Configuration for non-require minification/compression via
                                  # uglify using the --minify flag.
      # exclude:[/\\.min\\./]       # List of string paths and regexes to match files to exclude
                                  # when running minification. Any path with ".min." in its name,
                                  # like jquery.min.js, is assumed to already be minified and is
                                  # ignored by default. Paths can be relative to the
                                  # watch.compiledDir, or absolute.  Paths are to compiled files,
                                  # so '.js' rather than '.coffee'
  """

exports.validate = (config) ->
  errors = []
  if config.minify?
    if typeof config.minify is "object" and not Array.isArray(config.minify)

      if config.minify.exclude?
        if Array.isArray(config.minify.exclude)
          regexes = []
          newExclude = []
          for exclude in config.minify.exclude
            if typeof exclude is "string"
              newExclude.push __determinePath exclude, config.watch.compiledDir
            else if exclude instanceof RegExp
              regexes.push exclude.source
            else
              errors.push "minify.exclude must be an array of strings and/or regexes."
              break

          if regexes.length > 0
            config.minify.excludeRegex = new RegExp regexes.join("|"), "i"

          config.minify.exclude = newExclude
        else
          errors.push "minify.exclude must be an array."

    else
      errors.push "minify configuration must be an object."

  errors

__determinePath = (thePath, relativeTo) ->
  return thePath if windowsDrive.test thePath
  return thePath if thePath.indexOf("/") is 0
  path.join relativeTo, thePath
