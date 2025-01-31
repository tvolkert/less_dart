//source: less/tree/node.js 3.0.0 20160718

part of tree.less;

///
/// Base class for all tree nodes
///
abstract class Node {
  /// For extends visitor process
  List<Extend>        allExtends;

  /// The Node type could be used in the root ruleset
  bool                allowRoot = false;

  /// Info to optimize the node with cleanCss
  CleanCssContext     cleanCss;

  /// Filename and line coordinates for error debug
  DebugInfo           debugInfo;

  /// Selector elements
  List<Element>       elements;

  /// DetachedRuleset and MixinDefinition must be evaluated before other nodes
  /// in the Ruleset.eval() funciton
  bool                evalFirst = false;

  /// result from bool eval, used in condition
  bool                evaluated;

  /// hashCode own or inherited for object comparation
  int                 id;

  /// True if is a Ruleset or MixinDefinition
  bool                isRuleset = false;

  /// Only output css code for nodeVisible = true
  bool                nodeVisible;

  /// For operation node
  List<Node>          operands;

  /// for Rulesets and mixins process
  Node                originalRuleset;

  /// parent Node, used by index and fileInfo.
  Node                parent;

  /// The node has been parsed inside parenthesis `()`
  bool                parens = false; //Expression

  /// for expression evaluation
  bool                parensInOp = false; //See parsers.operand & Expression

  /// Some anonymous nodes are lazy parsed
  bool                parsed = false;

  ///
  bool                rootNode;

  /// The ruleset rules
  List<Node> rules;

  /// The ruleset selectors
  List<Selector>      selectors;

  /// the node value
  dynamic    value;

  /// Node visibility control
  int                 visibilityBlocks;

  ///
  /// Standard Node constructor
  Node() {
    id = hashCode;
  }

  ///
  /// Constructor for super call in derived class
  ///
  Node.init({
    FileInfo currentFileInfo,
    int index,
    this.operands,
    this.rules,
    this.value
    }) {
    _fileInfo = currentFileInfo;
    _index = index;
    id = hashCode;
  }

  /// Fields to show with genTree
  Map<String, dynamic> get treeField => null;

  /// Node name
  dynamic get         name => null; //String | List<Node>

  /// Node generic name == class name
  String get          type;

  // ---------------------- index
  int _index;

  /// returns index from this node or their parent
  int getIndex() => _index
      ?? parent?._index;
      //?? 0;  //return must be null to avoid error detached-ruleset-5

  /// index from this node or their parent, position in the less file
  int get index => getIndex();

  /// Save the index position
  set index(int value) {
    _index = value;
  }

//3.0.0 20160714
// var self = this;
// Object.defineProperty(this, "index", {
//   get: function() { return self.getIndex(); }
// });
// Node.prototype.getIndex = function() {
//     return this._index || (this.parent && this.parent.getIndex()) || 0;
// };
// ---------------------- index

  // ---------------------- fileInfo
  FileInfo _fileInfo;

  /// returns fileInfo from this node or their parent
  FileInfo fileInfo() => _fileInfo
      ?? parent?._fileInfo
      ?? new FileInfo();

  /// get fileInfo from this node or their parent
  FileInfo get currentFileInfo => fileInfo();

  /// Save fileInfo from this node
  set currentFileInfo(FileInfo value) {
    _fileInfo = value;
  }

//3.0.0 20160714
// Object.defineProperty(this, "currentFileInfo", {
//     get: function() { return self.fileInfo(); }
// });
// Node.prototype.fileInfo = function() {
//     return this._fileInfo || (this.parent && this.parent.fileInfo()) || {};
// };
// ---------------------- fileInfo

  /// Directive overrides it
  bool isCharset() => false;

  ///
  bool isRulesetLike() => false;

//3.0.0 20160716
// Node.prototype.isRulesetLike = function() { return false; };

  ///
  /// Update [parent] property in [nodes].
  ///
  /// [nodes] is Node | List<Node>
  ///
  void setParent(dynamic nodes, Node parent) {
    void set(Node node) {
      if (node == null) return;
      node.parent = parent;
    }
    if (nodes is List<Node>) {
      nodes.forEach(set);
    } else {
      set(nodes);
    }

//3.0.0 20160714
// Node.prototype.setParent = function(nodes, parent) {
//     function set(node) {
//         if (node && node instanceof Node) {
//             node.parent = parent;
//         }
//     }
//     if (Array.isArray(nodes)) {
//         nodes.forEach(set);
//     }
//     else {
//         set(nodes);
//     }
// };
}

  ///
  void throwAwayComments() {}

  ///
  /// Returns node transformed to css code
  ///
  String toCSS(Contexts context) {
    final Output output = new Output();
    genCSS(context, output);
    //if (context != null) context.avoidDartOptimization = true; //avoid dart context prune
    return output.toString();

//2.3.1
//   Node.prototype.toCSS = function (context) {
//       var strs = [];
//       this.genCSS(context, {
//           add: function(chunk, fileInfo, index) {
//               strs.push(chunk);
//           },
//           isEmpty: function () {
//               return strs.length === 0;
//           }
//       });
//       return strs.join('');
//   };
  }

  ///
  /// Writes in [output] the node transformed to CSS.
  ///
  void genCSS(Contexts context, Output output) {
    output.add(value);

//2.3.1
//  Node.prototype.genCSS = function (context, output) {
//      output.add(this.value);
//  };
  }

  ///
  void accept(VisitorBase visitor) {
    value = visitor.visit(value);

//2.3.1
//  Node.prototype.accept = function (visitor) {
//      this.value = visitor.visit(this.value);
//  };
  }

  ///
  /// Default evaluation - returns the node
  ///
  Node eval(Contexts context) => this;

//2.3.1
//  Node.prototype.eval = function () { return this; };

  ///
  /// Math [op] operation (+, - , *, /) with 2 numbers [a] and [b]
  ///
  num _operate(Contexts context, String op, num a, num b) {
    switch (op) {
        case '+': return a + b;
        case '-': return a - b;
        case '*': return a * b;
        case '/': return a / b;
    }
    return null;

//2.3.1
//  Node.prototype._operate = function (context, op, a, b) {
//      switch (op) {
//          case '+': return a + b;
//          case '-': return a - b;
//          case '*': return a * b;
//          case '/': return a / b;
//      }
//  };
  }

  ///
  /// Adjust the precision of [value] according to [context].numPrecision.
  /// 8 By default.
  ///
  /// [precision] to force
  ///
  num fround(Contexts context, num value, [int precision]) {
    if (value is int) return value;

    final int _precision = (precision == null || precision == -1)
        ? context?.numPrecision
        : precision;

    // add "epsilon" to ensure numbers like 1.000000005 (represented as 1.000000004999....) are properly rounded...
    final double result = value + 2e-16;
    return (_precision == null)
        ? value
        : double.parse(result.toStringAsFixed(_precision));

//2.3.1
//  Node.prototype.fround = function(context, value) {
//      var precision = context && context.numPrecision;
//      //add "epsilon" to ensure numbers like 1.000000005 (represented as 1.000000004999....) are properly rounded...
//      return (precision == null) ? value : Number((value + 2e-16).toFixed(precision));
//  };
  }

  ///
  /// Compares two nodes [a] and [b]
  ///
  /// Returns:
  ///
  ///     -1: a < b
  ///     0: a = b
  ///     1: a > b
  ///     and null  for other value for a != b
  ///
  static int compareNodes(Node a, Node b) {
    //new Logger().log('${a.type}: ${a.value} - ${b.type}: ${b.value}');

    // for "symmetric results" force toCSS-based comparison
    // of Quoted or Anonymous if either value is one of those
    if ((a is CompareNode) && !(b is Quoted || b is Anonymous)) {
      return (a as CompareNode).compare(b);
    } else if (b is CompareNode) {
      return negate((b as CompareNode).compare(a)); //-null => null
    } else if (a.runtimeType != b.runtimeType) {
      return null;
    }

    final dynamic aValue = a.value;
    final dynamic bValue = b.value;

    if (aValue is! List) return (aValue == bValue) ? 0 : null;
    if (aValue is List && bValue is List) {
      if (aValue.length != bValue.length) return null;
      for (int i = 0; i < aValue.length; i++) {
        if (Node.compareNodes(aValue[i], bValue[i]) != 0) return null;
      }
    }
    return 0;

//2.3.1
//  Node.compare = function (a, b) {
//      /* returns:
//       -1: a < b
//       0: a = b
//       1: a > b
//       and *any* other value for a != b (e.g. undefined, NaN, -2 etc.) */
//
//      if ((a.compare) &&
//          // for "symmetric results" force toCSS-based comparison
//          // of Quoted or Anonymous if either value is one of those
//          !(b.type === "Quoted" || b.type === "Anonymous")) {
//          return a.compare(b);
//      } else if (b.compare) {
//          return -b.compare(a);
//      } else if (a.type !== b.type) {
//          return undefined;
//      }
//
//      a = a.value;
//      b = b.value;
//      if (!Array.isArray(a)) {
//          return a === b ? 0 : undefined;
//      }
//      if (a.length !== b.length) {
//          return undefined;
//      }
//      for (var i = 0; i < a.length; i++) {
//          if (Node.compare(a[i], b[i]) !== 0) {
//              return undefined;
//          }
//      }
//      return 0;
//  };
  }

  ///
  /// numeric comparision between two number [a] and [b]
  ///
  /// Returns: -1 , 0 or +1
  ///
  static int numericCompare(num a, num b) => a.compareTo(b);

//    return (a < b)
//        ? - 1
//        : (a == b
//          ? 0
//          : (a > b ? 1 : null));

//2.2.0 ok
//  Node.numericCompare = function (a, b) {
//      return a  <  b ? -1
//          : a === b ?  0
//          : a  >  b ?  1 : undefined;
//  };

///
/// Returns true if this node represents root of was imported by reference
///
  bool blocksVisibility() {
    visibilityBlocks ??= 0;
    return visibilityBlocks != 0;

//2.5.3 20151120
// Node.prototype.blocksVisibility = function () {
//     if (this.visibilityBlocks == null) {
//         this.visibilityBlocks = 0;
//     }
//     return this.visibilityBlocks !== 0;
// };
  }

  ///
  void addVisibilityBlock() {
    visibilityBlocks ??= 0;
    visibilityBlocks++;

//2.5.3 20151120
// Node.prototype.addVisibilityBlock = function () {
//     if (this.visibilityBlocks == null) {
//         this.visibilityBlocks = 0;
//     }
//     this.visibilityBlocks = this.visibilityBlocks + 1;
// };
  }

  ///
  void removeVisibilityBlock() {
    visibilityBlocks ??= 0;
    visibilityBlocks--;

//2.5.3 20151120
// Node.prototype.removeVisibilityBlock = function () {
//     if (this.visibilityBlocks == null) {
//         this.visibilityBlocks = 0;
//     }
//     this.visibilityBlocks = this.visibilityBlocks - 1;
// };
  }

  ///
  /// Turns on node visibility, that is, if called node will be shown in output
  /// regardless of whether it comes from import by reference or not
  ///
  void ensureVisibility() {
    nodeVisible = true;

//2.5.3 20151120
// Node.prototype.ensureVisibility = function () {
//     this.nodeVisible = true;
// };
  }

  ///
  /// Turns off node visibility - if called node will NOT be shown in output regardless
  /// of whether it comes from import by reference or not
  ///
  void ensureInvisibility() {
    nodeVisible = false;

//2.5.3 20151120
// Node.prototype.ensureInvisibility = function () {
//     this.nodeVisible = false;
// };
  }

  ///
  /// return values:
  ///  false - the node must not be visible
  ///  true - the node must be visible
  ///  null - the node has the same visibility as its parent
  ///
  bool isVisible() => nodeVisible;

//2.5.3 20151120
// Node.prototype.isVisible = function () {
//     return this.nodeVisible;
// };

///
  VisibilityInfo visibilityInfo() => new VisibilityInfo(
      visibilityBlocks: visibilityBlocks,
      nodeVisible: nodeVisible
    );

//2.5.3 20151120
// Node.prototype.visibilityInfo = function() {
//     return {
//         visibilityBlocks: this.visibilityBlocks,
//         nodeVisible: this.nodeVisible
//     };
// };

  ///
  /// This node get the visibility from [info]
  ///
  void copyVisibilityInfo(VisibilityInfo info) {
    if (info == null) return;
    visibilityBlocks = info.visibilityBlocks;
    nodeVisible = info.nodeVisible;

//2.5.3 20151120
// Node.prototype.copyVisibilityInfo = function(info) {
//     if (!info) {
//         return;
//     }
//     this.visibilityBlocks = info.visibilityBlocks;
//     this.nodeVisible = info.nodeVisible;
// };
  }

  ///
  /// debug print the node tree
  ///
  StringBuffer toTree(LessOptions options) {
    final Contexts  env = new Contexts.eval(options);
    final Output    output = new Output();

    genTree(env, output);
    return output.value;
  }

  ///
  /// Writes in [output] the tree, for debug
  ///
  void genTree(Contexts env, Output output, [String prefix = '']) {
      genTreeTitle(env, output, prefix, type, toString());

      final int tabs = prefix.isEmpty ? 1 : 2;
      env.tabLevel = env.tabLevel + tabs ;

      if (treeField == null) {
        output.add('***** FIELDS NOT DEFINED in $type *****');
      } else {
        treeField.forEach((String fieldName, dynamic fieldValue) {
          genTreeField(env, output, fieldName, fieldValue);
        });
      }

      env.tabLevel = env.tabLevel - tabs;
  }

  ///
  /// Build the node tree title
  ///
  void genTreeTitle(Contexts env, Output output, String prefix, String type, String value) {
    final String tabStr = '  ' * env.tabLevel;
    output.add('$tabStr$prefix$type ($value)\n');
  }

  ///
  /// Build the subtree for a [fieldName], [fieldValue]
  ///
  void genTreeField(Contexts env, Output output, String fieldName, dynamic fieldValue) {
    final String tabStr = '  ' * env.tabLevel;

    if (fieldValue == null) {

    } else if (fieldValue is String) {
      if (fieldValue.isNotEmpty) output.add('$tabStr.$fieldName: String ($fieldValue)\n');
    } else if (fieldValue is num) {
      output.add('$tabStr.$fieldName: num (${fieldValue.toString()})\n');
    } else if (fieldValue is Node) {
      fieldValue.genTree(env, output, '.$fieldName: ');
    } else if (fieldValue is List && fieldValue.isEmpty) {

    } else if (fieldValue is List && fieldValue.isNotEmpty) {
      output.add('$tabStr.$fieldName: \n');
      env.tabLevel++;
      if (fieldValue.first is Node) {
        fieldValue.forEach((dynamic e) { // Node
          e.genTree(env, output, '- ');
        });
      } else if (fieldValue.first is MixinArgs) {
        fieldValue.forEach((dynamic a) { // MixinArgs
          a.genTree(env, output, '- ');
        });
      } else if (fieldValue.first is String) {
        final String tabStr = '  ' * env.tabLevel;
        fieldValue.forEach((dynamic s) { // String
          output.add('$tabStr- String ($s)\n');
        });
      } else if (fieldValue.first is num) {
        final String tabStr = '  ' * env.tabLevel;
        fieldValue.forEach((dynamic n) { // num
          output.add('$tabStr- num (${n.toString()})\n');
        });
      } else {
        output.add('*** field type not implemented ***');
      }
      env.tabLevel--;
    } else {
      output.add('$tabStr.$fieldName: ***********\n');
    }
  }
}

//-----------------------------------------------------------

///
abstract class CompareNode {
  /// Returns -1, 0 or +1
  int compare(Node x);
}

///
abstract class MakeImportantNode {
  ///
  Node makeImportant();
}

///
abstract class MatchConditionNode {
  ///
  List<Node> rules;
  ///
  bool matchCondition(List<MixinArgs> args, Contexts context);
  ///
  bool matchArgs(List<MixinArgs> args, Contexts context);
}

///
abstract class OperateNode<T> {
  //Node operate(Contexts context, String op, Node other);
  ///
  T operate(Contexts context, String op, T other);
}

///
abstract class SilentNode {
  ///
  bool isSilent(Contexts context);
}

///
class VisibilityInfo {
  ///
  int   visibilityBlocks;
  ///
  bool nodeVisible;

  ///
  VisibilityInfo({this.visibilityBlocks, this.nodeVisible});
}
