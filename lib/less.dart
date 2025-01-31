library less;

import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;

import 'src/environment/environment.dart';
import 'src/less_error.dart';
import 'src/less_options.dart';
import 'src/logger.dart';
import 'src/parser/parser.dart';
import 'src/render/render.dart';
import 'src/tree/tree.dart';

export 'src/contexts.dart';
export 'src/environment/environment.dart';
export 'src/file_info.dart';
export 'src/functions/functions.dart' show FunctionBase, DefineMethod;
export 'src/less_options.dart';
export 'src/parser/parser.dart';
export 'src/plugins/plugins.dart';
export 'src/render/render.dart';
export 'src/tree/tree.dart';
export 'src/visitor/visitor_base.dart';

///
class Less {
  ///
  bool          continueProcessing = true;

  /// process.exitCode to console
  int           exitCode = 0;

  /// return list of imported files
  List<String>  imports = <String>[];

  ///
  Logger        logger;

  ///
  LessOptions   _options;

  ///
  StringBuffer  stdin  = new StringBuffer();

  ///
  StringBuffer  stdout = new StringBuffer();

  ///
  StringBuffer  stderr = new StringBuffer();

  ///
  Less() {
    logger = new Logger(stderr); // care the order
    _options = new LessOptions();
    new Environment()..options = _options; //make global
  }

  ///
  void loggerReset() {
    logger.reset();
  }

  ///
  /// Transform a less file to css file.
  ///
  /// [args] has the options and input/output file names.
  /// [modifyOptions] let programtically modify the options.
  ///
  /// Example:
  ///   new Less.transform(args, modifyOptions: (options){
  ///    options.plugins = ...
  ///   });
  ///
  Future<int> transform(List<String> args, {Function modifyOptions}) {
    if (!argsFilter(args)) {
      exitCode = _options.parseError ? 1 : 0;
      return new Future<int>.value(exitCode);
    }
    if (!_options.validate()) {
      exitCode = _options.parseError ? 1 : 0;
      return new Future<int>.value(exitCode);
    }

    if (modifyOptions != null) modifyOptions(_options);
    _options.pluginLoader.start();

    if (_options.input != '-') {
      // Default to .less
      String filename = _options.input;
      if (path.extension(filename).isEmpty) filename = '$filename.less';

      final File file = new File(filename);
      if (!file.existsSync()) {
        logger.error('Error cannot open file ${_options.input}');
        exitCode = 3;
        return new Future<int>.value(exitCode);
      }

      return file
          .readAsString()
          .then((String content) => parseLessFile(content))
          .catchError((dynamic e) {
            logger.error('Error reading ${_options.input}');
            exitCode = 3;
            return new Future<int>.value(exitCode);
          });
    } else {
      return parseLessFile(stdin.toString());
    }
  }

  ///
  /// Process all arguments: -options and input/output
  ///
  bool argsFilter(List<String> args) {
    final RegExp regOption = new RegExp(r'^--?([a-z][0-9a-z-]*)(?:=(.*))?$', caseSensitive: false);
    final RegExp regPaths = new RegExp(r'^-I(.+)$', caseSensitive: true);
    Match match;
    bool continueProcessing = true;

    args.forEach((String arg) {
      if ((match = regPaths.firstMatch(arg)) != null) { //I suppose same as include_path  "-I path/to/directory"
        _options.paths.add(match[1]);
        return;
      }
      if ((match = regOption.firstMatch(arg)) != null) {
        if (continueProcessing) continueProcessing = _options.parse(match);
        return;
      }
      if (_options.input == '') {
        _options.input = arg;
        return;
      }
      if (_options.output == '') _options.output = arg;
    });
    return continueProcessing;
  }

  ///
  Future<int> parseLessFile(String data) {
    final Parser parser = new Parser(_options);
    return parser.parse(data).then((Ruleset tree) {
      RenderResult result;

      if (tree == null) return new Future<int>.value(exitCode);

      //debug
      if (_options.showTreeLevel == 0) {
        final String css = tree.toTree(_options).toString();
        stdout.write(css);
        return new Future<int>.value(exitCode);
      }

      try {
        result = new ParseTree(tree, parser.imports)
            .toCSS(_options.clone(), parser.context);
        imports = result.imports;

        if (!_options.lint) writeOutput(_options.output, result, _options);

      } on LessExceptionError catch (e) {
        logger.error(e.toString());
        exitCode = 2;
        return new Future<int>.value(exitCode);
      }

      return new Future<int>.value(exitCode);
    }).catchError((dynamic e) {
      logger.error(e.toString());
      exitCode = 1;
      return new Future<int>.value(exitCode);
    });
  }

  /// Writes css file, map file and dependencies
  void writeOutput(String output, RenderResult result, LessOptions options) {
    //if (option.depends) return //??

    //css
    if (output.isNotEmpty) {
      writeFile(output, result.css);
    } else {
      stdout.write(result.css);
    }

    //map
    if (options.sourceMap && !options.sourceMapOptions.sourceMapFileInline) {
      writeFile(options.sourceMapOptions.sourceMapFullFilename, result.map);
    }

    //dependencies
    if (options.depends) {
      logger.log('${options.outputBase}: ${result.imports.join(' ')}');
    }

//2.7.1 20160503
// var writeOutput = function(output, result, onSuccess) {
//     if (options.depends) {
//         onSuccess();
//     } else if (output) {
//         ensureDirectory(output);
//         fs.writeFile(output, result.css, {encoding: 'utf8'}, function (err) {
//             if (err) {
//                 var description = "Error: ";
//                 if (errno && errno.errno[err.errno]) {
//                     description += errno.errno[err.errno].description;
//                 } else {
//                     description += err.code + " " + err.message;
//                 }
//                 console.error('lessc: failed to create file ' + output);
//                 console.error(description);
//                 process.exitCode = 1;
//             } else {
//                 less.logger.info('lessc: wrote ' + output);
//                 onSuccess();
//             }
//         });
//     } else if (!options.depends) {
//         process.stdout.write(result.css);
//         onSuccess();
//     }
// };
  }

  /// Creates the file [filename] with [content]
  void writeFile(String filename, String content) {
    try {
      new File(filename)
          ..createSync(recursive: true)
          ..writeAsStringSync(content);
      logger.info('lessc: wrote $filename');
    } catch (e) {
      throw new LessExceptionError(new LessError(
          type: 'File',
          message: 'lessc: failed to create file $filename\n${e.toString()}'));
    }
  }
}
