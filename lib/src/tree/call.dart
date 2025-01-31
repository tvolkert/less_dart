//source: less/tree/call.js 3.5.0.beta 20180625

part of tree.less;

///
/// A function call node.
///
class Call extends Node {
  @override String        name;
  @override final String  type = 'Call';

  /// Function arguments
  List<Node>  args; // Expression | Dimension | Assignment

  /// Controls math on calc function
  bool calc;

  ///
  Call(this.name, this.args, {int index, FileInfo currentFileInfo})
      : super.init(currentFileInfo: currentFileInfo, index: index) {
    calc = (name == 'calc');

// 3.5.0.beta 20180625
//  var Call = function (name, args, index, currentFileInfo) {
//    this.name = name;
//    this.args = args;
//    this.calc = name === 'calc';
//    this._index = index;
//    this._fileInfo = currentFileInfo;
//  };
  }

  /// Fields to show with genTree
  @override Map<String, dynamic> get treeField => <String, dynamic>{
    'name': name,
    'args': args
  };

  ///
  @override
  void accept(covariant VisitorBase visitor) {
    if (args != null) args = visitor.visitArray(args);

//2.3.1
//  Call.prototype.accept = function (visitor) {
//      if (this.args) {
//          this.args = visitor.visitArray(this.args);
//      }
//  };
  }

  ///
  /// When evaluating a function call,
  /// we either find the function in `functions` [1],
  /// in which case we call it, passing the  evaluated arguments,
  /// if this returns null or we cannot find the function, we
  /// simply print it out as it appeared originally [2].
  ///
  /// The *functions.dart* file contains the built-in functions.
  ///
  /// The reason why we evaluate the arguments, is in the case where
  /// we try to pass a variable to a function, like: `saturate(@color)`.
  /// The function should receive the value, not the variable.
  ///
  @override
  Node eval(Contexts context) {
    // Turn off math for calc(), and switch back on for evaluating nested functions
    final bool currentMathContext = context.mathOn;
    context.mathOn = !calc;
    if (calc || context.inCalc) context.enterCalc();

    final List<Node> args = this.args.map((Node a) => a.eval(context)).toList();
    if (calc || context.inCalc) context.exitCalc();
    context.mathOn = currentMathContext;

    final FunctionCaller funcCaller = new FunctionCaller(name, context, index, currentFileInfo);
    dynamic _result;
    Node result;

    if (funcCaller.isValid()) {
      try {
        _result = funcCaller.call(args);
      } catch (e) {
        String message = LessError.getMessage(e);
        message = (message.isEmpty) ? '' : ': $message';
        final String type = LessError.getType(e);

        final LessError error = LessError.transform(e,
            type: (type?.isNotEmpty ?? false) ? type : 'Runtime',
            index: index,
            filename: currentFileInfo.filename,
            line: LessError.getErrorLine(e),
            column: LessError.getErrorColumn(e))
        ..message = 'error evaluating function `$name`$message';

        throw new LessExceptionError(error);
      }

      if (_result != null) {
        // Results that that are not nodes are cast as Anonymous nodes
        // Falsy values or booleans are returned as empty nodes
        result = _result is Node
            ? _result
            : (_result is bool)
                ? new Anonymous(null)
                : new Anonymous(_result.toString());
        return result
            ..index = _index
            ..currentFileInfo = _fileInfo;
      }
    }

    return new Call(name, args, index: index, currentFileInfo: currentFileInfo);

// 3.5.0 beta 20180625
//  Call.prototype.eval = function (context) {
//    /**
//     * Turn off math for calc(), and switch back on for evaluating nested functions
//     */
//    var currentMathContext = context.mathOn;
//    context.mathOn = !this.calc;
//    if (this.calc || context.inCalc) {
//      context.enterCalc();
//    }
//    var args = this.args.map(function (a) { return a.eval(context); });
//    if (this.calc || context.inCalc) {
//      context.exitCalc();
//    }
//    context.mathOn = currentMathContext;
//
//    var result, funcCaller = new FunctionCaller(this.name, context, this.getIndex(), this.fileInfo());
//
//    if (funcCaller.isValid()) {
//      try {
//        result = funcCaller.call(args);
//      } catch (e) {
//        throw {
//          type: e.type || 'Runtime',
//          message: 'error evaluating function `' + this.name + '`' +
//              (e.message ? ': ' + e.message : ''),
//          index: this.getIndex(),
//          filename: this.fileInfo().filename,
//          line: e.lineNumber,
//          column: e.columnNumber
//        };
//      }
//
//      if (result !== null && result !== undefined) {
//        // Results that that are not nodes are cast as Anonymous nodes
//        // Falsy values or booleans are returned as empty nodes
//        if (!(result instanceof Node)) {
//          if (!result || result === true) {
//            result = new Anonymous(null);
//          }
//          else {
//            result = new Anonymous(result.toString());
//          }
//
//        }
//        result._index = this._index;
//        result._fileInfo = this._fileInfo;
//        return result;
//      }
//
//    }
//
//    return new Call(this.name, args, this.getIndex(), this.fileInfo());
//  };
  }

  ///
  @override
  void genCSS(Contexts context, Output output) {
    if (cleanCss != null) return genCleanCSS(context, output);

    output.add('$name(', fileInfo: currentFileInfo, index: index);

    for (int i = 0; i < args.length; i++) {
      args[i].genCSS(context, output);
      if (i + 1 < args.length) output.add(', ');
    }

    output.add(')');

//3.0.0 20160714
// Call.prototype.genCSS = function (context, output) {
//     output.add(this.name + "(", this.fileInfo(), this.getIndex());
//
//     for (var i = 0; i < this.args.length; i++) {
//         this.args[i].genCSS(context, output);
//         if (i + 1 < this.args.length) {
//             output.add(", ");
//         }
//     }
//
//     output.add(")");
// };
  }

  /// clean-css output
  void genCleanCSS(Contexts context, Output output) {
    output.add('$name(', fileInfo: currentFileInfo, index: index);

    for (int i = 0; i < args.length; i++) {
      args[i].genCSS(context, output);
      if (i + 1 < args.length)
          output.add(',');
    }

    output.add(')');
  }

  @override
  String toString() {
    final Output output = new Output();
    genCSS(null, output);
    return output.toString();
  }
}
