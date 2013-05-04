"use strict";
/*
TODO
1) Config for maps or no maps
2) if maps configed and not build , create and write map to name.map and write original unminified source to name.source
3) Handle clean
*/

var clean, logger, path, uglify, _minifyCSS, _minifyJS, _performJSMinify,
  __slice = [].slice,
  _this = this;

path = require("path");

uglify = require("uglify-js");

clean = require('clean-css');

logger = require('logmimosa');

exports.registration = function(config, register) {
  var e;

  e = config.extensions;
  if (config.isMinify) {
    register(['add', 'update', 'buildFile'], 'beforeWrite', _minifyJS, __slice.call(e.javascript));
    register(['add', 'update', 'buildExtension'], 'beforeWrite', _minifyJS, __slice.call(e.template));
  }
  if (config.isOptimize || config.isMinify) {
    return register(['add', 'update', 'buildExtension'], 'beforeWrite', _minifyCSS, __slice.call(e.css));
  }
};

_performJSMinify = function(file, isBuild) {
  var code, compressed_ast, compressor, err, inFileName, outFileName, source, stream, toplevel_ast;

  source = file.outputFileText;
  inFileName = file.inputFileName;
  outFileName = file.outputFileName;
  try {
    stream = uglify.OutputStream();
    /*
    else
      source_map = uglify.SourceMap
        file: outFileName
        root: undefined
        orig: undefined
      uglify.OutputStream source_map: source_map
    */

    toplevel_ast = uglify.parse(source, {
      filename: inFileName
    });
    toplevel_ast.figure_out_scope();
    compressor = uglify.Compressor({
      warnings: false
    });
    compressed_ast = toplevel_ast.transform(compressor);
    compressed_ast.figure_out_scope();
    compressed_ast.compute_char_frequency();
    compressed_ast.mangle_names({
      except: ['require', 'requirejs', 'define', 'exports', 'module']
    });
    compressed_ast.print(stream);
    code = stream + "";
    /*
    unless isBuild
      mapName = "#{path.basename(outFileName)}.json"
      mapOutputFile = path.join path.dirname(outFileName), mapName
      code += "\n//@ sourceMappingURL=file://" + mapOutputFile
      mapInfo = {outputFileName:mapOutputFile, outputFileText:source_map+""}
    */

    return {
      code: code,
      mapInfo: null
    };
  } catch (_error) {
    err = _error;
    logger.warn("Minification failed on [[ " + outFileName + " ]], writing unminified source\n" + err);
    return {
      code: source
    };
  }
};

_minifyJS = function(config, options, next) {
  var done, hasFiles, i, maps, _ref;

  hasFiles = ((_ref = options.files) != null ? _ref.length : void 0) > 0;
  if (!hasFiles) {
    return next();
  }
  i = 0;
  maps = [];
  done = function() {
    var mapInfo, _i, _len;

    if (maps.length > 0) {
      for (_i = 0, _len = maps.length; _i < _len; _i++) {
        mapInfo = maps[_i];
        options.files.push(mapInfo);
      }
    }
    return next();
  };
  return options.files.forEach(function(file) {
    var minified;

    if (file.outputFileName && file.outputFileText) {
      if (config.minify.excludeRegex && file.outputFileName.match(config.minify.excludeRegex)) {
        logger.debug("Not going to minify [[ " + file.outputFileName + " ]], it has been excluded with a regex.");
      } else if (config.minify.exclude.indexOf(file.outputFileName) > -1) {
        logger.debug("Not going to minify [[ " + file.outputFileName + " ]], it has been excluded with a string path.");
      } else {
        logger.debug("Running minification on [[ " + file.outputFileName + " ]]");
        minified = _performJSMinify(file, config.isBuild);
        file.outputFileText = minified.code;
        if (minified.mapInfo) {
          maps.push(minified.mapInfo);
        }
      }
    }
    if (++i === options.files.length) {
      return done();
    }
  });
};

_minifyCSS = function(config, options, next) {
  var hasFiles, i, _ref;

  hasFiles = ((_ref = options.files) != null ? _ref.length : void 0) > 0;
  if (!hasFiles) {
    return next();
  }
  i = 0;
  return options.files.forEach(function(file) {
    var fileName, text;

    fileName = file.outputFileName;
    text = file.outputFileText;
    if (config.minify.excludeRegex && fileName.match(config.minify.excludeRegex)) {
      logger.debug("Not going to minify [[ " + fileName + " ]], it has been excluded with a regex.");
    } else if (config.minify.exclude.indexOf(fileName) > -1) {
      logger.debug("Not going to minify [[ " + fileName + " ]], it has been excluded with a string path.");
    } else {
      logger.debug("Running minification on [[ " + fileName + " ]]");
      file.outputFileText = clean.process(text);
    }
    if (++i === options.files.length) {
      return next();
    }
  });
};
