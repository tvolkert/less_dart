//source: less/tree/dimension.js 3.0.3 20180340

part of tree.less;

///
class Unit extends Node implements CompareNode {
  @override final String type = 'Unit';

  ///
  String          backupUnit;
  ///
  List<String>    denominator;
  ///
  List<String>    numerator;

  ///
  Unit([
      List<String> numerator = const <String>[],
      List<String> denominator = const <String>[],
      this.backupUnit
      ]) {
    this.numerator = numerator.sublist(0)..sort(); //clone
    this.denominator = denominator.sublist(0)..sort();
    if (backupUnit == null && this.numerator.isNotEmpty) {
      backupUnit = this.numerator[0];
    }

//3.0.0 20160714
// var Unit = function (numerator, denominator, backupUnit) {
//     this.numerator = numerator ? utils.copyArray(numerator).sort() : [];
//     this.denominator = denominator ? utils.copyArray(denominator).sort() : [];
//     if (backupUnit) {
//         this.backupUnit = backupUnit;
//     } else if (numerator && numerator.length) {
//         this.backupUnit = numerator[0];
//     }
// };
  }

  /// Fields to show with genTree
  @override Map<String, dynamic> get treeField => <String, dynamic>{
    'numerator': numerator,
    'denominator': denominator
  };

  ///
  Unit clone() =>
      new Unit(numerator.sublist(0), denominator.sublist(0), backupUnit);

//3.0.0 20160714
// Unit.prototype.clone = function () {
//     return new Unit(utils.copyArray(this.numerator), utils.copyArray(this.denominator), this.backupUnit);
// };

  ///
  @override
  void genCSS(Contexts context, Output output) {
    // Dimension checks the unit is singular and throws an error if in strict math mode.
    final bool stricUnits = context?.strictUnits ?? false;

    if (numerator.length == 1) {
      output.add(numerator[0]); // the ideal situation
    } else if (!stricUnits && backupUnit != null) {
      output.add(backupUnit);
    } else if (!stricUnits && denominator.isNotEmpty) {
      output.add(denominator[0]);
    }

//2.4.0
//  Unit.prototype.genCSS = function (context, output) {
//      // Dimension checks the unit is singular and throws an error if in strict math mode.
//      var strictUnits = context && context.strictUnits;
//      if (this.numerator.length === 1) {
//          output.add(this.numerator[0]); // the ideal situation
//      } else if (!strictUnits && this.backupUnit) {
//          output.add(this.backupUnit);
//      } else if (!strictUnits && this.denominator.length) {
//          output.add(this.denominator[0]);
//      }
//  };
  }

  ///
  @override
  String toString() =>
      denominator.fold(numerator.join('*'), (String prev, String d) => '$prev/$d');

//2.3.1
//  Unit.prototype.toString = function () {
//      var i, returnStr = this.numerator.join("*");
//      for (i = 0; i < this.denominator.length; i++) {
//          returnStr += "/" + this.denominator[i];
//      }
//      return returnStr;
//  };

  //--- CompareNode

  /// Returns -1 for different, 0 for equal
  @override
  int compare(Node other) => isUnit(other.toString()) ? 0 : null;

//2.3.1
//  Unit.prototype.compare = function (other) {
//      return this.is(other.toString()) ? 0 : undefined;
//  };

  ///
  //is in js
  bool isUnit(String unitString) =>
      toString().toUpperCase() == unitString.toUpperCase();

//2.3.1
//  Unit.prototype.is = function (unitString) {
//      return this.toString().toUpperCase() === unitString.toUpperCase();
//  };

  ///
  bool isLength(Contexts context) {
    final RegExp re = new RegExp(r'^(px|em|ex|ch|rem|in|cm|mm|pc|pt|ex|vw|vh|vmin|vmax)$', caseSensitive: false);
    return re.hasMatch(toCSS(context));

//3.0.3 20180430
//  Unit.prototype.isLength = function () {
//    return RegExp('^(px|em|ex|ch|rem|in|cm|mm|pc|pt|ex|vw|vh|vmin|vmax)$', 'gi').test(this.toCSS());
//  };
  }

  ///
  bool isAngle(Contexts context) {
    final RegExp re = new RegExp(r'rad|deg|grad|turn'); //i?
    return re.hasMatch(toCSS(context));
  }

  ///
  /// True if numerator & denominator isEmpty
  ///
  bool isEmpty() => numerator.isEmpty && denominator.isEmpty;

//2.3.1
//  Unit.prototype.isEmpty = function () {
//      return this.numerator.length === 0 && this.denominator.length === 0;
//  };

  ///
  bool isSingular() => (numerator.length <= 1 && denominator.isEmpty);

//2.3.1
//  Unit.prototype.isSingular = function() {
//      return this.numerator.length <= 1 && this.denominator.length === 0;
//  };

  ///
  /// Process numerator and denominator according to [callback] function
  /// String callback(String unit, bool isDenominator)
  /// callback returns new unit
  ///
  void map(Function callback) {
    for (int i = 0; i < numerator.length; i++) {
      numerator[i] = callback(numerator[i], false);
    }

    for (int i = 0; i < denominator.length; i++) {
      denominator[i] = callback(denominator[i], true);
    }

//2.3.1
//  Unit.prototype.map = function(callback) {
//      var i;
//
//      for (i = 0; i < this.numerator.length; i++) {
//          this.numerator[i] = callback(this.numerator[i], false);
//      }
//
//      for (i = 0; i < this.denominator.length; i++) {
//          this.denominator[i] = callback(this.denominator[i], true);
//      }
//  };
  }

  ///
  Map<String, String> usedUnits() {
    Map<String, double>       group;
    String                    groupName;
    final Map<String, String> result = <String, String>{};

    // ignore: avoid_positional_boolean_parameters
    String mapUnit(String atomicUnit, bool isDenominator) {
      if (group.containsKey(atomicUnit) && !result.containsKey(groupName)) {
        result[groupName] = atomicUnit;
      }
      return atomicUnit;
    }

    for (groupName in UnitConversions.groups.keys) {
      if (UnitConversions.groups.containsKey(groupName)) {//redundant?
        group = UnitConversions.groups[groupName];
        map(mapUnit);
      }
    }

    return result;

//2.3.1
//  Unit.prototype.usedUnits = function() {
//      var group, result = {}, mapUnit;
//
//      mapUnit = function (atomicUnit) {
//          /*jshint loopfunc:true */
//          if (group.hasOwnProperty(atomicUnit) && !result[groupName]) {
//              result[groupName] = atomicUnit;
//          }
//
//          return atomicUnit;
//      };
//
//      for (var groupName in unitConversions) {
//          if (unitConversions.hasOwnProperty(groupName)) {
//              group = unitConversions[groupName];
//
//              this.map(mapUnit);
//          }
//      }
//
//      return result;
//  };
  }

  ///
  /// Normalize numerator and denominator after operations
  ///
  void cancel() {
    String                  atomicUnit;
    final Map<String, int>  counter = <String, int>{};

    for (int i = 0; i < numerator.length; i++) {
      atomicUnit = numerator[i];
      if (!counter.containsKey(atomicUnit)) counter[atomicUnit] = 0;
      counter[atomicUnit] = counter[atomicUnit] + 1;
    }

    for (int i = 0; i < denominator.length; i++) {
      atomicUnit = denominator[i];
      if (!counter.containsKey(atomicUnit)) counter[atomicUnit] = 0;
      counter[atomicUnit] = counter[atomicUnit] - 1;
    }

    numerator = <String>[];
    denominator = <String>[];

    for (atomicUnit in counter.keys) {
      if (counter.containsKey(atomicUnit)) {
        final int count = counter[atomicUnit];
        if (count > 0) {
          for (int i = 0; i < count; i++) {
            numerator.add(atomicUnit);
          }
        } else if (count < 0) {
          for (int i = 0; i < -count; i++) {
            denominator.add(atomicUnit);
          }
        }
      }
    }

    numerator.sort();
    denominator.sort();

//2.3.1
//  Unit.prototype.cancel = function () {
//      var counter = {}, atomicUnit, i;
//
//      for (i = 0; i < this.numerator.length; i++) {
//          atomicUnit = this.numerator[i];
//          counter[atomicUnit] = (counter[atomicUnit] || 0) + 1;
//      }
//
//      for (i = 0; i < this.denominator.length; i++) {
//          atomicUnit = this.denominator[i];
//          counter[atomicUnit] = (counter[atomicUnit] || 0) - 1;
//      }
//
//      this.numerator = [];
//      this.denominator = [];
//
//      for (atomicUnit in counter) {
//          if (counter.hasOwnProperty(atomicUnit)) {
//              var count = counter[atomicUnit];
//
//              if (count > 0) {
//                  for (i = 0; i < count; i++) {
//                      this.numerator.push(atomicUnit);
//                  }
//              } else if (count < 0) {
//                  for (i = 0; i < -count; i++) {
//                      this.denominator.push(atomicUnit);
//                  }
//              }
//          }
//      }
//
//      this.numerator.sort();
//      this.denominator.sort();
//  };
  }
}
