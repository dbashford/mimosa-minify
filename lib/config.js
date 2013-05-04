"use strict";exports.defaults = function() {
  return {
    minify: {
      exclude: [/\.min\./]
    }
  };
};

exports.placeholder = function() {
  return "\t\n\n  # minify:                     # Configuration for non-require minification/compression via\n                                # uglify using the --minify flag.\n    # exclude:[/\\.min\\./]       # List of string paths and regexes to match files to exclude\n                                # when running minification. Any path with \".min.\" in its name,\n                                # like jquery.min.js, is assumed to already be minified and is\n                                # ignored by default. Paths can be relative to the\n                                # watch.compiledDir, or absolute.  Paths are to compiled files,\n                                # so '.js' rather than '.coffee'";
};

exports.validate = function(config, validators) {
  var errors;

  errors = [];
  if (validators.ifExistsIsObject(errors, "minify config", config.minify)) {
    validators.ifExistsFileExcludeWithRegexAndString(errors, "minify.exclude", config.minify, config.watch.compiledDir);
  }
  return errors;
};
