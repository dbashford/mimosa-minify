exports.defaults = ->
  minify:
    exclude:["\.min\."]

exports.placeholder = ->
  """
  \t

    # minify:                               # Configuration for non-require minification/compression via uglify using the --minify flag.
      # exclude:["\.min\."]                 # List of regexes to exclude files when running minification.  Any path with ".min." in its
                                            # name, like jquery.min.js, is assumed to already be minified and is ignored by default.
                                            # Override this property if you have other files that you'd like to exempt from minification
  """

exports.validate = (config) ->
  errors = []
  if config.minify?
    if typeof config.minify is "object"
      if config.minify.exclude?
        if Array.isArray(config.minify.exclude)
          for ex in config.minify.exclude
            unless typeof ex is "string"
              errors.push "minify.exclude must be an array of strings"
              break
        else
          errors.push "minify.exclude must be an array."
    else
      errors.push "minify configuration must be an object."
  errors