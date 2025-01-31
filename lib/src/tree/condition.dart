//source: less/tree/condition.js 3.0.0 20160714

part of tree.less;

///
class Condition extends Node {
  @override final String type = 'Condition';

  ///
  Node    lvalue;
  ///
  bool    negate;
  ///
  String  op;
  ///
  Node    rvalue;

  ///
  /// Conditions are < = > <= >= and or
  ///
  ///     lvalue op rvalue
  ///     @a1 = true
  ///
  Condition(String op, this.lvalue, this.rvalue, {
      int index,
      this.negate = false
      }) : super.init(index: index) {

    this.op = op.trim();

//3.0.0 20160714
// var Condition = function (op, l, r, i, negate) {
//   this.op = op.trim();
//   this.lvalue = l;
//   this.rvalue = r;
//   this._index = i;
//   this.negate = negate;
// };
  }

  /// Fields to show with genTree
  @override Map<String, dynamic> get treeField => <String, dynamic>{
    'op': op,
    'lvalue': lvalue,
    'rvalue': rvalue
  };

  ///
  @override
  void accept(covariant VisitorBase visitor) {
    lvalue = visitor.visit(lvalue) as Node;
    rvalue = visitor.visit(rvalue) as Node;

//2.3.1
//  Condition.prototype.accept = function (visitor) {
//      this.lvalue = visitor.visit(this.lvalue);
//      this.rvalue = visitor.visit(this.rvalue);
//  };
  }

  ///
  /// Compare (lvalue op rvalue) returning true or false (in this.evaluated)
  ///
  @override
  Node eval(Contexts context) {
    //
    bool comparation(String op, Node aNode, Node bNode) {
      final bool a = aNode is Condition ? aNode.evaluated : false;
      final bool b = bNode is Condition ? bNode.evaluated : false;

      switch (op) {
        case 'and':
          return a && b;
        case 'or':
          return a || b;
        default:
          switch (Node.compareNodes(aNode, bNode)) {
            case -1:
              return (op == '<' || op == '=<' || op == '<=');
            case 0:
              return (op == '=' || op == '>=' || op == '=<' || op == '<=');
            case 1:
              return (op == '>' || op == '>=');
            default:
              return false;
          }
      }
    }

    evaluated = comparation(op, lvalue.eval(context), rvalue.eval(context));
    evaluated = negate ? !evaluated : evaluated;
    return this; //this.evaluated was the js return

//2.3.1
//  Condition.prototype.eval = function (context) {
//      var result = (function (op, a, b) {
//          switch (op) {
//              case 'and': return a && b;
//              case 'or':  return a || b;
//              default:
//                  switch (Node.compare(a, b)) {
//                      case -1: return op === '<' || op === '=<' || op === '<=';
//                      case  0: return op === '=' || op === '>=' || op === '=<' || op === '<=';
//                      case  1: return op === '>' || op === '>=';
//                          default: return false;
//                  }
//          }
//      })(this.op, this.lvalue.eval(context), this.rvalue.eval(context));
//
//      return this.negate ? !result : result;
//  };
  }

  @override
  String toString() => '${lvalue.toString()} $op ${rvalue.toString()}';
}
