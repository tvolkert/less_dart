//source: less/tree/atrule.js 3.0.0 20160719

part of tree.less;

///
/// Directive such as
///
///   `@charset "UTF-8"`
///
class AtRule extends DirectiveBase {
  @override final String    type = 'AtRule';
  @override covariant Node  value;

  ///
  /// value is Node | String
  /// ex.: AtRule('@charset', 'utf-8')
  ///
  AtRule(String name, dynamic value, {
      dynamic rules,
      int index,
      FileInfo currentFileInfo,
      DebugInfo debugInfo,
      VisibilityInfo visibilityInfo,
      bool isRooted = false
      }) : super(
          name: name,
          index: index,
          currentFileInfo: currentFileInfo,
          debugInfo: debugInfo,
          isRooted: isRooted,
          visibilityInfo: visibilityInfo) {
    //
    this.value = (value is Node)
        ? value
        : (value != null) ? new Anonymous(value) : null;

    if (rules != null) {
      if (rules is List<Ruleset>) {
        this.rules = rules;
      } else {
        this.rules = <Ruleset>[rules as Ruleset];
        this.rules[0].selectors = new Selector(<Element>[],
            index: index,
            currentFileInfo: currentFileInfo)
            .createEmptySelectors();
      }
      this.rules.forEach((Node rule) {
        (rule as Ruleset).allowImports = true;
      });
      setParent(rules, this);
    }

    allowRoot = true;

//3.0.0 20160719
// var AtRule = function (name, value, rules, index, currentFileInfo, debugInfo, isRooted, visibilityInfo) {
//     var i;
//
//     this.name  = name;
//     this.value = (value instanceof Node) ? value : (value ? new Anonymous(value) : value);
//     if (rules) {
//         if (Array.isArray(rules)) {
//             this.rules = rules;
//         } else {
//             this.rules = [rules];
//             this.rules[0].selectors = (new Selector([], null, null, index, currentFileInfo)).createEmptySelectors();
//         }
//         for (i = 0; i < this.rules.length; i++) {
//             this.rules[i].allowImports = true;
//         }
//         this.setParent(this.rules, this);
//     }
//     this._index = index;
//     this._fileInfo = currentFileInfo;
//     this.debugInfo = debugInfo;
//     this.isRooted = isRooted || false;
//     this.copyVisibilityInfo(visibilityInfo);
//     this.allowRoot = true;
// };
  }

  @override
  String toString() => name;
}
