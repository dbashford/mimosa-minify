"use strict";
var clean, fs, logger, path, uglify, _minifyCSS, _minifyJS, _performJSMinify,
  __slice = [].slice;

path = require("path");

fs = require("fs");

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

_performJSMinify = function(config, file) {
  var code, compressed_ast, compressor, createSourceMap, err, inFileName, mapInfo, mapName, outFileName, rootName, source, sourceMapJSON, sourceMapRoot, source_map, stream, toplevel_ast;

  source = file.outputFileText;
  inFileName = file.inputFileName;
  outFileName = file.outputFileName;
  rootName = outFileName.replace(path.extname(outFileName), '');
  mapName = "" + rootName + ".map";
  createSourceMap = !config.isBuild && (file.sourceMap != null);
  try {
    stream = createSourceMap ? (source_map = uglify.SourceMap({
      file: outFileName,
      root: inFileName,
      orig: JSON.parse(file.sourceMap)
    }), uglify.OutputStream({
      source_map: source_map
    })) : uglify.OutputStream();
    toplevel_ast = uglify.parse(source, {
      filename: outFileName
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
    if (createSourceMap) {
      code += "\n/*\n//@ sourceMappingURL=" + path.basename(file.sourceMapName);
      code += "\n*/\n";
      sourceMapRoot = inFileName.replace(path.basename(inFileName), '');
      sourceMapRoot = sourceMapRoot.replace(config.watch.sourceDir, '');
      sourceMapRoot = sourceMapRoot.slice(0, -1);
      sourceMapJSON = JSON.parse(source_map.toString());
      sourceMapJSON.sourceRoot = sourceMapRoot;
      mapInfo = {
        outputFileName: file.sourceMapName,
        outputFileText: JSON.stringify(sourceMapJSON)
      };
    }
    return {
      code: code,
      mapInfo: mapInfo
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
        minified = _performJSMinify(config, file);
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
