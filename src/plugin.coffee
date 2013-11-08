"use strict"

path = require "path"
fs = require "fs"

uglify = require "uglify-js"
clean  = require('clean-css')()
logger = require 'logmimosa'

exports.registration = (config, register) ->
  e = config.extensions

  if config.isMinify
    register ['add','update','buildFile'],      'beforeWrite', _minifyJS,  e.javascript
    register ['add','update','buildExtension'], 'beforeWrite', _minifyJS, e.template

  if config.isOptimize or config.isMinify
    console.log e.css
    register ['add','update','buildExtension', 'buildFile'], 'beforeWrite', _minifyCSS, e.css

_performJSMinify = (config, file) ->
  source = file.outputFileText
  inFileName = file.inputFileName
  outFileName = file.outputFileName
  rootName = outFileName.replace(path.extname(outFileName), '')
  mapName = "#{rootName}.map"
  createSourceMap = not config.isBuild and file.sourceMap?

  try
    stream = if createSourceMap
      source_map = uglify.SourceMap
        file: outFileName
        root: inFileName
        orig: JSON.parse(file.sourceMap)
      uglify.OutputStream source_map: source_map
    else
      uglify.OutputStream()

    toplevel_ast = uglify.parse source, {filename:outFileName}
    toplevel_ast.figure_out_scope()
    compressor = uglify.Compressor warnings:false
    compressed_ast = toplevel_ast.transform compressor
    compressed_ast.figure_out_scope()
    compressed_ast.compute_char_frequency()
    compressed_ast.mangle_names({except:['require','requirejs','define','exports','module']})
    compressed_ast.print(stream)
    code = stream+""

    if createSourceMap
      # @ is deprecated but # not widely supported in current release browsers
      code += '\n/*\n//@ sourceMappingURL=' + path.basename(file.sourceMapName)
      code += "\n*/\n"

      sourceMapRoot = inFileName.replace(path.basename(inFileName), '')
      sourceMapRoot = sourceMapRoot.replace(config.watch.sourceDir, '')
      sourceMapRoot = sourceMapRoot.slice(0, -1)
      sourceMapJSON = JSON.parse(source_map.toString())
      sourceMapJSON.sourceRoot = sourceMapRoot

      mapInfo = {outputFileName:file.sourceMapName, outputFileText:JSON.stringify(sourceMapJSON)}

    {code:code, mapInfo:mapInfo}

  catch err
    logger.warn "Minification failed on [[ #{outFileName} ]], writing unminified source\n#{err}"
    {code:source}

_minifyJS = (config, options, next) ->
  hasFiles = options.files?.length > 0
  return next() unless hasFiles

  i = 0
  maps = []

  done = ->
    if maps.length > 0
      options.files.push mapInfo for mapInfo in maps
    next()

  options.files.forEach (file) ->
    if file.outputFileName and file.outputFileText
      if config.minify.excludeRegex and file.outputFileName.match config.minify.excludeRegex
        logger.debug "Not going to minify [[ #{file.outputFileName} ]], it has been excluded with a regex."
      else if config.minify.exclude.indexOf(file.outputFileName) > -1
        logger.debug "Not going to minify [[ #{file.outputFileName} ]], it has been excluded with a string path."
      else
        logger.debug "Running minification on [[ #{file.outputFileName} ]]"
        minified = _performJSMinify config, file
        file.outputFileText = minified.code
        if minified.mapInfo
          maps.push minified.mapInfo

    done() if ++i is options.files.length

_minifyCSS = (config, options, next) ->
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
      file.outputFileText = clean.minify text

    next() if ++i is options.files.length
