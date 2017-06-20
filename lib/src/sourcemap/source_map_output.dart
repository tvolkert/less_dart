// source: less/source-map-output.js 2.5.0

part of sourcemap.less;

///
class SourceMapOutput extends Output {
  ///
  int                 column = 0;
  ///
  Map<String, int>    contentsIgnoredCharsMap;
  ///
  Map<String, String> contentsMap;
  ///
  int                 indexGenerated = 0;
  ///
  int                 lineNumber = 0;
  ///
  Map<String, String> normalizeCache = <String, String>{};
  ///
  String              outputFilename;
  ///
  bool                outputSourceFiles;
  ///
  Ruleset             rootNode;
  ///
  String              sourceMap; //result
  ///
  String              sourceMapBasepath;
  ///
  String              sourceMapFilename;
  ///
  SourceMapBuilder    sourceMapGenerator; //class instance
  ///
  bool                sourceMapFileInline;
  ///
  String              sourceMapRootpath;
  ///
  String              sourceMapURL;

  ///
  SourceMapOutput(
      {Map<String, int> this.contentsIgnoredCharsMap,
      Ruleset this.rootNode,
      Map<String, String> this.contentsMap,
      String sourceMapFilename,
      String this.sourceMapURL,
      String this.outputFilename,
      String sourceMapBasepath, //abs?
      String sourceMapRootpath,
      bool this.outputSourceFiles,
      bool this.sourceMapFileInline}) {

    if (sourceMapFilename != null)
        this.sourceMapFilename = sourceMapFilename.replaceAll('\\', '/');
    if (sourceMapBasepath != null)
        this.sourceMapBasepath = sourceMapBasepath.replaceAll('\\', '/');
    if (sourceMapRootpath != null) {
      this.sourceMapRootpath = sourceMapRootpath.replaceAll('\\', '/');
      if (!this.sourceMapRootpath.endsWith('/'))
          // ignore: prefer_interpolation_to_compose_strings
          this.sourceMapRootpath += '/';
    } else {
      this.sourceMapRootpath = '';
    }

    sourceMapGenerator = new SourceMapBuilder();

//2.4.0
//  var SourceMapOutput = function (options) {
//      this._css = [];
//      this._rootNode = options.rootNode;
//      this._contentsMap = options.contentsMap;
//      this._contentsIgnoredCharsMap = options.contentsIgnoredCharsMap;
//      if (options.sourceMapFilename) {
//          this._sourceMapFilename = options.sourceMapFilename.replace(/\\/g, '/');
//      }
//      this._outputFilename = options.outputFilename;
//      this.sourceMapURL = options.sourceMapURL;
//      if (options.sourceMapBasepath) {
//          this._sourceMapBasepath = options.sourceMapBasepath.replace(/\\/g, '/');
//      }
//      if (options.sourceMapRootpath) {
//          this._sourceMapRootpath = options.sourceMapRootpath.replace(/\\/g, '/');
//          if (this._sourceMapRootpath.charAt(this._sourceMapRootpath.length - 1) !== '/') {
//              this._sourceMapRootpath += '/';
//          }
//      } else {
//          this._sourceMapRootpath = "";
//      }
//      this._outputSourceFiles = options.outputSourceFiles;
//      this._sourceMapGeneratorConstructor = environment.getSourceMapGenerator();
//
//      this._lineNumber = 0;
//      this._column = 0;
//  };
  }

  ///
  String normalizeFilename (String file) {
    if (normalizeCache.containsKey(file))
        return normalizeCache[file];

    String filename = file.replaceAll('\\', '/');

    if (sourceMapBasepath != null && filename.startsWith(sourceMapBasepath)) {
      filename = filename.substring(sourceMapBasepath.length);
      if (filename.startsWith('\\') || filename.startsWith('/'))
          filename = filename.substring(1);
    }

    final String result = path.normalize('${sourceMapRootpath ?? ''}$filename');
    normalizeCache[file] = result;
    return result;

//2.4.0
//  SourceMapOutput.prototype.normalizeFilename = function(filename) {
//      filename = filename.replace(/\\/g, '/');
//
//      if (this._sourceMapBasepath && filename.indexOf(this._sourceMapBasepath) === 0) {
//          filename = filename.substring(this._sourceMapBasepath.length);
//          if (filename.charAt(0) === '\\' || filename.charAt(0) === '/') {
//              filename = filename.substring(1);
//          }
//      }
//      return (this._sourceMapRootpath || "") + filename;
//  };
  }

  ///
  /// genCSS call 'output.add'. This is 'output' for sourcemaps generation
  /// [s] String | Node
  ///
  @override
  void add(Object s, {FileInfo fileInfo, int index = 0, bool mapLines = false}) {
    if (s == null)
        return;

    final String  chunk = (s is String) ? s : s.toString();
    String        columns;
    int           _index = index;
    List<String>  lines;
    String        sourceColumns;
    List<String>  sourceLines;

    //ignore adding empty strings
    if (chunk.isEmpty)
        return;

    if (fileInfo != null) {
      String inputSource = contentsMap[fileInfo.filename];

      // remove vars/banner added to the top of the file
      if (contentsIgnoredCharsMap[fileInfo.filename] != null) {
        // adjust the index
        _index -= contentsIgnoredCharsMap[fileInfo.filename];
        if (_index < 0)
            _index = 0;
        // adjust the source
        inputSource = inputSource.substring(contentsIgnoredCharsMap[fileInfo.filename]);
      }
      inputSource = inputSource.substring(0, _index);
      sourceLines = inputSource.split('\n');
      sourceColumns = sourceLines.last;
    }

    lines = chunk.split('\n');
    columns = lines.last;

    if (fileInfo != null) {
      if (!mapLines) {
        final SourcemapData data = new SourcemapData(
            originalIndex: _index,
            originalLine: sourceLines.length - 1,
            originalColumn: sourceColumns.length,
            originalFile: normalizeFilename(fileInfo.filename),
            generatedIndex: indexGenerated,
            generatedLine: lineNumber,
            generatedColumn: column,
            generatedFile: normalizeFilename(outputFilename));
        if (data != null)
            sourceMapGenerator.addLocation(data.original, data.generated, null);
      } else { // @import (inline)
        for (int i = 0; i < lines.length; i++) {
          final SourcemapData data = new SourcemapData(
              originalIndex: _index,
              originalLine: sourceLines.length + i - 1,
              originalColumn: (i == 0) ? sourceColumns.length : 0,
              originalFile: normalizeFilename(fileInfo.filename),
              generatedIndex: indexGenerated,
              generatedLine: lineNumber + i,
              generatedColumn: (i == 0) ? column : 0,
              generatedFile: normalizeFilename(outputFilename));

          if (data != null)
              sourceMapGenerator.addLocation(data.original, data.generated, null);
        }
      }
    }

    if (lines.length == 1) {
      column += columns.length;
    } else {
      lineNumber += lines.length - 1;
      column = columns.length;
    }

    super.add(chunk);
    indexGenerated += chunk.length;

//2.4.0
//  SourceMapOutput.prototype.add = function(chunk, fileInfo, index, mapLines) {
//
//      //ignore adding empty strings
//      if (!chunk) {
//          return;
//      }
//
//      var lines,
//          sourceLines,
//          columns,
//          sourceColumns,
//          i;
//
//      if (fileInfo) {
//          var inputSource = this._contentsMap[fileInfo.filename];
//
//          // remove vars/banner added to the top of the file
//          if (this._contentsIgnoredCharsMap[fileInfo.filename]) {
//              // adjust the index
//              index -= this._contentsIgnoredCharsMap[fileInfo.filename];
//              if (index < 0) { index = 0; }
//              // adjust the source
//              inputSource = inputSource.slice(this._contentsIgnoredCharsMap[fileInfo.filename]);
//          }
//          inputSource = inputSource.substring(0, index);
//          sourceLines = inputSource.split("\n");
//          sourceColumns = sourceLines[sourceLines.length - 1];
//      }
//
//      lines = chunk.split("\n");
//      columns = lines[lines.length - 1];
//
//      if (fileInfo) {
//          if (!mapLines) {
//              this._sourceMapGenerator.addMapping({ generated: { line: this._lineNumber + 1, column: this._column},
//                  original: { line: sourceLines.length, column: sourceColumns.length},
//                  source: this.normalizeFilename(fileInfo.filename)});
//          } else {
//              for (i = 0; i < lines.length; i++) {
//                  this._sourceMapGenerator.addMapping({ generated: { line: this._lineNumber + i + 1, column: i === 0 ? this._column : 0},
//                      original: { line: sourceLines.length + i, column: i === 0 ? sourceColumns.length : 0},
//                      source: this.normalizeFilename(fileInfo.filename)});
//              }
//          }
//      }
//
//      if (lines.length === 1) {
//          this._column += columns.length;
//      } else {
//          this._lineNumber += lines.length - 1;
//          this._column = columns.length;
//      }
//
//      this._css.push(chunk);
//  };
  }

  ///
  String toCSS(Contexts context) {
    final Map<String, String> contents = <String, String>{};
    Map<dynamic, dynamic>     json; //<String, dynamic> dynamic = String | int
    String                    sourceMapURL = '';

    if (outputSourceFiles) { //--source-map-less-inline
      for (String filename in contentsMap.keys) {
        String source = contentsMap[filename];
        if (contentsIgnoredCharsMap[filename] != null)
            source = source.substring(contentsIgnoredCharsMap[filename]);
        contents[normalizeFilename(filename)] = source;
      }
    }

    rootNode.genCSS(context, this);

    if (!super.isEmpty) {
      String sourceMapContent;
      if (outputSourceFiles) {//--source-map-less-inline
        json = sourceMapGenerator.build(normalizeFilename(outputFilename));
        final List<String> sourcesContent = <String>[];
        for (String filename in json['sources']) {
          sourcesContent.add(contents[filename]);
        }
        json['sourcesContent'] = sourcesContent;
        sourceMapContent = JSON.encode(json);
      } else {
        sourceMapContent = sourceMapGenerator.toJson(normalizeFilename(outputFilename));
      }

      if (sourceMapURL.isNotEmpty) {
        sourceMapURL = this.sourceMapURL;
      } else if (sourceMapFilename.isNotEmpty) {
        sourceMapURL = normalizeFilename(sourceMapFilename);
      }

      //export results
      this.sourceMapURL = sourceMapURL;
      sourceMap = sourceMapContent;
    }

    return super.toString();

//2.4.0
//  SourceMapOutput.prototype.toCSS = function(context) {
//      this._sourceMapGenerator = new this._sourceMapGeneratorConstructor({ file: this._outputFilename, sourceRoot: null });
//
//      if (this._outputSourceFiles) {
//          for (var filename in this._contentsMap) {
//              if (this._contentsMap.hasOwnProperty(filename))
//              {
//                  var source = this._contentsMap[filename];
//                  if (this._contentsIgnoredCharsMap[filename]) {
//                      source = source.slice(this._contentsIgnoredCharsMap[filename]);
//                  }
//                  this._sourceMapGenerator.setSourceContent(this.normalizeFilename(filename), source);
//              }
//          }
//      }
//
//      this._rootNode.genCSS(context, this);
//
//      if (this._css.length > 0) {
//          var sourceMapURL,
//              sourceMapContent = JSON.stringify(this._sourceMapGenerator.toJSON());
//
//          if (this.sourceMapURL) {
//              sourceMapURL = this.sourceMapURL;
//          } else if (this._sourceMapFilename) {
//              sourceMapURL = this._sourceMapFilename;
//          }
//          this.sourceMapURL = sourceMapURL;
//
//          this.sourceMap = sourceMapContent;
//      }
//
//      return this._css.join('');
//  };
  }
}

///
/// Build data to use in SourceMapBuilder.addLocation
///
class SourcemapData {
  ///
  SourceLocation  original;
  ///
  int             originalIndex;
  ///
  int             originalLine;
  ///
  int             originalColumn;
  ///
  String          originalFile;
  ///
  SourceLocation  generated;
  ///
  int             generatedIndex;
  ///
  int             generatedLine;
  ///
  int             generatedColumn;
  ///
  String          generatedFile;
  ///
  static SourcemapData last;

  /// Compares with last call. If is same line, return null
  factory SourcemapData(
      {int originalIndex,
      int originalLine,
      int originalColumn,
      String originalFile,
      int generatedIndex,
      int generatedLine,
      int generatedColumn,
      String generatedFile}) {

    if (last != null) {
      if (last.originalIndex == originalIndex &&
          last.originalFile  == originalFile &&
          last.generatedLine == generatedLine)
          return null;
    }

    final SourcemapData data = new SourcemapData.create(
        originalIndex, originalLine, originalColumn, originalFile,
        generatedIndex, generatedLine, generatedColumn, generatedFile)
        ..original = new SourceLocation(originalIndex,
            line: originalLine,
            column: originalColumn,
            sourceUrl: originalFile)
        ..generated = new SourceLocation(generatedIndex,
            line: generatedLine,
            column: generatedColumn,
            sourceUrl: generatedFile);

    last = data;
    return data;
  }

///
SourcemapData.create(
    this.originalIndex,
    this.originalLine,
    this.originalColumn,
    this.originalFile,
    this.generatedIndex,
    this.generatedLine,
    this.generatedColumn,
    this.generatedFile);
}
