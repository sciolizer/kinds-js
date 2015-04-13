/*
 varBind :: MonadError TypeError m => Tyvar -> Type -> m Subst
 varBind u t
 | t == TVar u = return nullSubst
 | u `S.member` tv t = throwError $ OccursCheck u t
 | kind u /= kind t = throwError $ KindMismatch (kind u) (kind t)
 | otherwise = return (u --> t)

 */

var IllegalArgumentException = function(param, why) {
  this.param = param;
  this.why = why;
  this.toString = function() {
    var prefix = "Illegal argument for '" + param + "'";
    return why ? prefix + ": " + why : prefix;
  };
};

var CheckIsException = function(type, property, expected, actual, val) {
  this.type = type;
  this.property = property;
  this.expected = expected;
  this.actual = actual;
  this.val = val;
  this.toString = function() {
    return "check(" + type + ") " + property + ": expected " + expected + " but found " + actual + " on " + val;
  };
};

var check = function(pred, val) {
  return pred(val);
};

var isTypeOf = function(name) {
  if (typeof name !== "string") {
    throw new IllegalArgumentException('name', 'not a string');
  }
  return function(val) {
    if (typeof val !== name) {
      throw new CheckIsException(name, "typeof", name, typeof val, val);
    }
  };
};

var isString = isTypeOf("string");
var isObject = isTypeOf("object");
var isFunction = isTypeOf("function");

var any = function() {
  return true;
};

var properties = function(obj) {
  check(isObject, obj);
  var result = [];
  for (var p in obj) {
    if (obj.hasOwnProperty(p)) {
      result.push(p);
    }
  }
  return result;
};

var adt = function(name, f) {
  check(isString, name);
  check(isFunction, f);
  var errorPrefix = "check(" + name + "): ";
  return function(val) {
    var sumSchema = f();
    console.log("sumSchema = " + sumSchema);
    check(isObject, sumSchema);
    var expectedConstructors = [];
    for (var p in sumSchema) {
      if (sumSchema.hasOwnProperty(p)) {
        expectedConstructors.push(p);
      }
    }
    var actualConstructors = [];
    for (var k in val) {
      if (val.hasOwnProperty(k)) {
        if (sumSchema.hasOwnProperty(k)) {
          actualConstructors.push(k);
          var productSchema = sumSchema[k];

          console.log("k = " + k);
          console.log("sumSchema[k] = " + sumSchema[k]);
          check(sumSchema[k], val[k]);
        } else {
          throw new CheckIsException(name, "constructor", "one of " + expectedConstructors, k, val);
        }
      }
    }
    if (actualConstructors === 0) {
      throw new CheckIsException(name, "constructor", "one of " + expectedConstructors, "[]", val);
    } else if (actualConstructors !== 1) {
      throw new CheckIsException(name, "constructor", "one of " + expectedConstructors, actualConstructors, val);
    }
  }
};


var isKind = adt("kind", function() {
  return {
    Star: {},
    Function: { left: isKind, right: isKind }
  };
});

var isVariable = adt("variable", function() {
  return {
    Variable: { name: isString, kind: isKind }
  };
});

var isConstructor = adt("constructor", function() {
  return {
    Constructor: { name: isString, kind: isKind }
  };
});

var isType = adt("type", function() {
  return {
    Apply: { left: isType, right: isType },
    Variable: { variable: isVariable },
    Constructor: { constructor: isConstructor }
  };
});

var bindVariable = function(variable, t) {

};

var applySubstitution = function(substitution, t) {
  if (t.Variable) {
    if (substitution.hasOwnProperty(t.Variable.variable.Variable.name)) {
      return substitution[t.Variable.variable.Variable.name];
    } else {
      return t;
    }
  } else if (t.Apply) {
    return {
      Apply: {
        left: applySubstitution(substitution, t.Apply.left),
        right: applySubstitution(substitution, t.Apply.right)
      }
    };
  } else {
    return t;
  }
};

var joinSubstitutions = function(s1, s2) {
  var result = [];
  for (var i = 0; i < s2.length; i++) {
    result.push({
      variable: s2[i].variable,
      type: applySubstitution(s1, s2[i].type)
    });
  }
  for (var j = 0; j < s1.length; j++) {
    result.push(s1[j]);
  }
  return result;
};

var mgu = function(t1, t2) {
  if (t1.Apply && t2.Apply) {
    var s1 = mgu(t1.Apply.left, t2.Apply.left);
    var s2 = mgu(applySubstitution(s1, t1.Apply.right), applySubstitution(s1, t2.Apply.right));
    return joinSubstitutions(s2, s1);
  } else if (t1.Variable) {
    return bindVariable(t1.Variable.variable, t2);
  } else if (t2.Variable) {
    return bindVariable(t2.Variable.variable, t1);
  } else if (t1.Constructor && t2.Constructor && t1.Constructor.name === t2.Constructor.name) {
    return nullSubstitution();
  } else {
    throw new Error("cannot unify " + t1 + " with " + t2);
  }
};

var applyFunction = function(funcType, argType) {
  if (
    funcType.Apply &&
    funcType.Apply.left.Apply &&
    funcType.Apply.left.Apply.left.Constructor &&
    funcType.Apply.left.Apply.left.Constructor.name === "(->)") {
    var expectedInput = funcType.Apply.left.Apply.right;
    var expectedOutput = funcType.Apply.right;
    var substitution = mgu(expectedInput, expectedOutput);
    return applySubstitution(substitution, expectedOutput);
  }
  throw new Error("not a function");
};

module.exports = {
  IllegalArgumentException: IllegalArgumentException,
  CheckIsException: CheckIsException,
  check: check,
  isTypeOf: isTypeOf,
  isString: isString,
  adt: adt,
  adtKind: isKind,
  adtVariable: isVariable,
  adtConstructor: isConstructor,
  adtType: isType
};
