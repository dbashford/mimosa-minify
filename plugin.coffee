"use strict"

jsp =   require("uglify-js").parser
pro =   require("uglify-js").uglify
clean  = require 'clean-css'
logger = require 'logmimosa'

exports.registration = (config, register) ->
  e = config.extensions

  if config.isMinify
    register ['add','update','buildFile'],      'beforeWrite', _minifyJS,  [e.javascript...]
    register ['add','update','buildExtension'], 'beforeWrite',  _minifyJS,  [e.template...]

  if config.isOptimize or config.isMinify
    register ['add','update','buildExtension'], 'beforeWrite', _minifyCSS, [e.css...]

_performJSMinify = (source, fileName) ->
  try
    text = jsp.parse source
    text = pro.ast_mangle text, {except:['require','requirejs','define']}
    text = pro.ast_squeeze text
    pro.gen_code text
  catch err
    logger.warn "Minification failed on [[ #{fileName} ]], writing unminified source\n#{err}"

_minifyJS = (config, options, next) =>
  return next() unless options.files?.length > 0

  i = 0
  options.files.forEach (file) =>
    fileName = file.outputFileName
    text = file.outputFileText
    if fileName and text
      if config.minify.excludeRegex and fileName.match config.minify.excludeRegex
        logger.debug "Not going to minify [[ #{fileName} ]], it has been excluded with a regex."
      else if config.minify.exclude.indexOf(fileName) > -1
        logger.debug "Not going to minify [[ #{fileName} ]], it has been excluded with a string path."
      else
        logger.debug "Running minification on [[ #{fileName} ]]"
        file.outputFileText = _performJSMinify(text, fileName)

    next() if ++i is options.files.length

_minifyCSS = (config, options, next) =>
  return next() unless options.files?.length > 0

  i = 0
  options.files.forEach (file) ->
    fileName = file.outputFileName
    text = file.outputFileText
    if config.minify.excludeRegex and fileName.match config.minify.excludeRegex
      logger.debug "Not going to minify [[ #{fileName} ]], it has been excluded with a regex."
    else if config.minify.exclude.indexOf(fileName) > -1
      logger.debug "Not going to minify [[ #{fileName} ]], it has been excluded with a string path."
    else
      logger.debug "Running minification on [[ #{fileName} ]]"
      file.outputFileText = clean.process text

    next() if ++i is options.files.length