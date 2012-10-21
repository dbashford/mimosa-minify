jsp =   require("uglify-js").parser
pro =   require("uglify-js").uglify
clean  = require 'clean-css'
logger = require 'mimosa-logger'

exports.registration = (config, register) ->
  e = config.extensions

  if config.isMinify
    register ['add','update','buildFile'],      'afterCompile', _minifyJS,  [e.javascript...]
    register ['add','update','buildExtension'], 'beforeWrite',  _minifyJS,  [e.template...]

  if config.isOptimize or config.isMinify
    register ['add','update','buildExtension'], 'afterCompile', _minifyCSS, [e.css...]

exports.performJSMinify = (source, fileName) ->
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
      if @config.minify.exclude and fileName.match @config.minify.exclude
        logger.debug "Not going to minify [[ #{fileName} ]], it has been excluded."
      else
        logger.debug "Running minification on [[ #{fileName} ]]"
        file.outputFileText = exports.performJSMinify(text, fileName)

    next() if ++i is options.files.length

_minifyCSS = (config, options, next) =>
  return next() unless options.files?.length > 0

  logger.debug "Cleaning/optimizing CSS [[ #{options.files} ]]"
  i = 0
  options.files.forEach (file) ->
    file.outputFileText = clean.process file.outputFileText
    next() if ++i is options.files.length