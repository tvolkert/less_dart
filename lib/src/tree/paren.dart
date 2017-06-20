//source: less/tree/paren.js 2.5.0

part of tree.less;

///
class Paren extends Node {
  @override final String    type = 'Paren';
  @override covariant Node  value;

  ///
  Paren(Node this.value);

  ///
  @override
  void genCSS(Contexts context, Output output) {
    output.add('(');
    value.genCSS(context, output);
    output.add(')');

//2.3.1
//  Paren.prototype.genCSS = function (context, output) {
//      output.add('(');
//      this.value.genCSS(context, output);
//      output.add(')');
//  };
  }

  ///
  @override
  Paren eval(Contexts context) => new Paren(value.eval(context));

//2.3.1
//  Paren.prototype.eval = function (context) {
//      return new Paren(this.value.eval(context));
//  };
}
