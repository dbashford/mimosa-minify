"use strict"

###
TODO
1) Config for maps or no maps
2) if maps configed and not build , create and write map to name.map and write original unminified source to name.source
3) Handle clean
###

path = require "path"

uglify = require "uglify-js"
clean  = require 'clean-css'
logger = require 'logmimosa'

exports.registration = (config, register) ->
  e = config.extensions

  if config.isMinify
    register ['add','update','buildFile'],      'beforeWrite', _minifyJS,  [e.javascript...]
    register ['add','update','buildExtension'], 'beforeWrite',  _minifyJS,  [e.template...]

  if config.isOptimize or config.isMinify
    register ['add','update','buildExtension'], 'beforeWrite', _minifyCSS, [e.css...]

_performJSMinify = (file, isBuild) ->
  source = file.outputFileText
  inFileName = file.inputFileName
  outFileName = file.outputFileName

  try
    #stream = if isBuild
    stream = uglify.OutputStream()
    ###
    else
      source_map = uglify.SourceMap
        file: outFileName
        root: undefined
        orig: undefined
      uglify.OutputStream source_map: source_map
    ###

    toplevel_ast = uglify.parse source, {filename:inFileName}
    toplevel_ast.figure_out_scope()
    compressor = uglify.Compressor warnings:false
    compressed_ast = toplevel_ast.transform compressor
    compressed_ast.figure_out_scope()
    compressed_ast.compute_char_frequency()
    compressed_ast.mangle_names({except:['require','requirejs','define','exports','module']})
    compressed_ast.print(stream)

    code = stream+""

    ###
    unless isBuild
      mapName = "#{path.basename(outFileName)}.json"
      mapOutputFile = path.join path.dirname(outFileName), mapName
      code += "\n//@ sourceMappingURL=file://" + mapOutputFile
      mapInfo = {outputFileName:mapOutputFile, outputFileText:source_map+""}
    ###

    #{code:code, mapInfo:mapInfo}
    {code:code, mapInfo:null}

  catch err
    logger.warn "Minification failed on [[ #{outFileName} ]], writing unminified source\n#{err}"
    {code:source}

_minifyJS = (config, options, next) =>
  hasFiles = options.files?.length > 0
  return next() unless hasFiles

  i = 0
  maps = []

  done = =>
    if maps.length > 0
      options.files.push mapInfo for mapInfo in maps
    next()

  options.files.forEach (file) =>
    if file.outputFileName and file.outputFileText
      if config.minify.excludeRegex and file.outputFileName.match config.minify.excludeRegex
        logger.debug "Not going to minify [[ #{file.outputFileName} ]], it has been excluded with a regex."
      else if config.minify.exclude.indexOf(file.outputFileName) > -1
        logger.debug "Not going to minify [[ #{file.outputFileName} ]], it has been excluded with a string path."
      else
        logger.debug "Running minification on [[ #{file.outputFileName} ]]"
        minified = _performJSMinify(file, config.isBuild)
        file.outputFileText = minified.code
        maps.push minified.mapInfo if minified.mapInfo

    done() if ++i is options.files.length

_minifyCSS = (config, options, next) =>
  hasFiles = options.files?.length > 0
  return next() unless hasFiles

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