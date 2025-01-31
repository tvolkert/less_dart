//source: less/tree/variable-call.js 3.8.1 20181129

part of tree.less;

///
class VariableCall extends Node {
  @override final String name = null;
  @override final String type = 'VariableCall';

  ///
  String variable;

  ///
  VariableCall(this.variable, int index, FileInfo currentFileInfo)
      : super.init(currentFileInfo: currentFileInfo, index: index) {
    allowRoot = true;

// 3.5.0.beta.4 20180630
//  var VariableCall = function (variable, index, currentFileInfo) {
//      this.variable = variable;
//      this._index = index;
//      this._fileInfo = currentFileInfo;
//      this.allowRoot = true;
//  };
}

  /// Fields to show with genTree
  @override Map<String, dynamic> get treeField => <String, dynamic>{
    'variable': variable
  };

  ///
  @override
  Ruleset eval(Contexts context) {
    final Node result = new Variable(variable, index, currentFileInfo).eval(context);
    DetachedRuleset detachedRuleset;
    final LessExceptionError error = new LessExceptionError(new LessError(
        message: 'Could not evaluate variable call $variable'));

    if (result is! DetachedRuleset) {
      List<Node> rules;
      Ruleset rs;
      if (result is Ruleset) {
        rs = result;
      } else if (result is Nodeset) {
        rules = result.rules;
      } else if (result.value is List<Node>) {
        rules = result.value;
      } else {
        throw error;
      }
      rs ??= new Ruleset(null, rules);
      detachedRuleset = new DetachedRuleset(rs);
    } else {
      detachedRuleset = result;
    }

    if (detachedRuleset.ruleset != null) {
      return detachedRuleset.callEval(context);
    }

    throw error;

// 3.8.1 20181129
//  VariableCall.prototype.eval = function (context) {
//      var rules, detachedRuleset = new Variable(this.variable, this.getIndex(), this.fileInfo()).eval(context),
//          error = new LessError({message: 'Could not evaluate variable call ' + this.variable});
//
//      if (!detachedRuleset.ruleset) {
//          if (detachedRuleset.rules) {
//              rules = detachedRuleset;
//          }
//          else if (Array.isArray(detachedRuleset)) {
//              rules = new Ruleset('', detachedRuleset);
//          }
//          else if (Array.isArray(detachedRuleset.value)) {
//              rules = new Ruleset('', detachedRuleset.value);
//          }
//          else {
//              throw error;
//          }
//          detachedRuleset = new DetachedRuleset(rules);
//      }
//      if (detachedRuleset.ruleset) {
//          return detachedRuleset.callEval(context);
//      }
//      throw error;
//  };
  }

  @override
  String toString() => variable;
}
