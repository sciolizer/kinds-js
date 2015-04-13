class IllegalArgumentException
  constructor: (@param, @why) ->
    @name = 'IllegalArgumentException'
    @message = @.toString()
    Error.captureStackTrace(this)
  toString: ->
    prefix = "Illegal argument for '" + @param + "'"
    why ? prefix + ": " + why : prefix

class CheckIsException extends Error
  constructor: (@type, @property, @expected, @actual, @val) ->
    @name = 'CheckIsException'
    @message = @.toString()
    Error.captureStackTrace(this)
  toString: ->
    "check(" + @type + ") " + @property + ": expected " + @expected + " but found " + @actual + " on " + @val

check = (pred, val) -> pred(val)

checkReturn = (pred, f) ->
  result = f()
  console.log "pred = ", pred
  check pred, result
  result

isTypeOf = (name) ->
  if typeof name != 'string'
    throw new IllegalArgumentException('name', 'not a string')
  return (val) ->
    if typeof val != name
      throw new CheckIsException(name, 'typeof', name, typeof val, val)

isBoolean = isTypeOf 'boolean'
isString = isTypeOf 'string'
isObject = isTypeOf 'object'
isFunction = isTypeOf 'function'
isArray = (eachIs) ->
  (val) ->
    check isObject, val
    if val.constructor != Array
      throw new CheckIsException('array', 'constructor', 'Array', val.constructor, val)
    console.log "val = ", val
    console.log "eachIs = ", eachIs
    for v in val
      check eachIs, v

any = -> true

adt = (name, schemaProvider) ->
  check isString, name
  check isFunction, schemaProvider
  errorPrefix = "check(" + name + "): "
  (val) ->
    if typeof val != "object"
      throw new CheckIsException(name, "type", "object", typeof val, val)
    sumSchema = schemaProvider()
    check isObject, sumSchema
    badConstructor = (actualConstructors) ->
      expectedConstructors = (c for own c, cv of sumSchema)
      throw new CheckIsException(name, "constructor", "one of " + expectedConstructors, actualConstructors, val)
    actualConstructors = for own k, valFields of val
      if not sumSchema.hasOwnProperty k
        badConstructor(k)
      productSchema = sumSchema[k]
      expectedFields = (f for own f, fv of productSchema)
      actualFields = for own f, fv of valFields
        if not productSchema.hasOwnProperty f
          throw new CheckIsException(name + "." + constructor + '.' + f, 'defined', 'not defined', val)
        check productSchema[f], fv
        f
      if expectedFields.length != actualFields.length
        throw new CheckIsException(name + '.' + constructor, 'fields', expectedFields, actualFields, val)
    if actualConstructors.length == 0
      badConstructor('[]')
    else if actualConstructors.length != 1
      badConstructor(actualConstructors)

isKind = adt 'kind', -> {
  Star: {}
  Function: { left: isKind, right: isKind }
}

isVariable = adt 'variable', -> {
  Variable: {name: isString, kind: isKind }
}

isConstructor = adt 'constructor', -> {
  Constructor: { name: isString, kind: isKind }
}

isType = adt 'type', -> {
  Apply: { left: isType, right: isType }
  Variable: { variable: isVariable }
  Constructor: {constructor: isConstructor }
}

nullSubst = -> []

eqKind = (left, right) ->
  check isKind, left
  check isKind, right
  checkReturn isBoolean, ->
    if left.Star
      right.Star != undefined
    else if right.Star
      false
    else
      eqKind(left.Function.left, right.Function.left) && eqKind(left.Function.right, right.Function.right)

class OccursError extends Error
  constructor: (@variable, @type) ->
    @name = 'OccursError'
    @message = @.toString()
    Error.captureStackTrace(this)
  toString: ->
    @variable + " occurs in " + @type

class KindMismatchError extends Error
  constructor: (@left, @right) ->
    @name = 'KindMismatchError'
    @message = @.toString()
    Error.captureStackTrace(this)
  toString: ->
    @left + " != " + @right

typeKind = (type) ->
  check isType, type
  checkReturn isKind, ->
    if type.Variable
      console.log "hello"
      console.log "type.Variable = ", type.Variable
      type.Variable.variable.Variable.kind
    else if type.Constructor
      type.Constructor.constructor.Constructor.kind
    else if type.Apply
      tk = typeKind(type.Apply.left)
      if tk.Star
        throw new Error("malformed Apply of Star")
      tk.Function.right
    else
      throw new Error("Unreachable")

isBinding = adt 'binding', -> {
  Binding: { variable: isVariable, type: isType }
}

isSubst = isArray isBinding

singletonSubst = (variable, type) ->
  check isVariable, variable
  check isType, type
  checkReturn isSubst, ->
    [{Binding:{variable:variable,type:type}}]

bindVariable = (variable, t) ->
  check isVariable, variable
  check isType, t
  checkReturn isSubst, ->
    if t.Variable && t.Variable.variable.Variable.name == variable.name
      nullSubst()
    else if typeVariables(t).indexOf(variable.name) != -1
      throw new OccursError(variable.name, t)
    else if !eqKind(variable.kind, typeKind(t))
      throw new KindMismatchError(variable.kind, typeKind(t))
    else
      singletonSubst(variable, t)

#
#var bindVariable = function(variable, t) {
#
#};
#
#var applySubstitution = function(substitution, t) {
#  if (t.Variable) {
#    if (substitution.hasOwnProperty(t.Variable.variable.Variable.name)) {
#      return substitution[t.Variable.variable.Variable.name];
#    } else {
#      return t;
#    }
#  } else if (t.Apply) {
#    return {
#      Apply: {
#        left: applySubstitution(substitution, t.Apply.left),
#        right: applySubstitution(substitution, t.Apply.right)
#      }
#    };
#  } else {
#    return t;
#  }
#};
#
#var joinSubstitutions = function(s1, s2) {
#  var result = [];
#  for (var i = 0; i < s2.length; i++) {
#    result.push({
#      variable: s2[i].variable,
#      type: applySubstitution(s1, s2[i].type)
#    });
#  }
#  for (var j = 0; j < s1.length; j++) {
#    result.push(s1[j]);
#  }
#  return result;
#};
#
#var mgu = function(t1, t2) {
#  if (t1.Apply && t2.Apply) {
#    var s1 = mgu(t1.Apply.left, t2.Apply.left);
#    var s2 = mgu(applySubstitution(s1, t1.Apply.right), applySubstitution(s1, t2.Apply.right));
#    return joinSubstitutions(s2, s1);
#  } else if (t1.Variable) {
#    return bindVariable(t1.Variable.variable, t2);
#  } else if (t2.Variable) {
#    return bindVariable(t2.Variable.variable, t1);
#  } else if (t1.Constructor && t2.Constructor && t1.Constructor.name === t2.Constructor.name) {
#    return nullSubstitution();
#  } else {
#    throw new Error("cannot unify " + t1 + " with " + t2);
#  }
#};
#
#var applyFunction = function(funcType, argType) {
#  if (
#    funcType.Apply &&
#    funcType.Apply.left.Apply &&
#    funcType.Apply.left.Apply.left.Constructor &&
#    funcType.Apply.left.Apply.left.Constructor.name === "(->)") {
#    var expectedInput = funcType.Apply.left.Apply.right;
#    var expectedOutput = funcType.Apply.right;
#    var substitution = mgu(expectedInput, expectedOutput);
#    return applySubstitution(substitution, expectedOutput);
#  }
#  throw new Error("not a function");
#};
#
module.exports = {
  adt
  checkReturn
  eqKind
  isBinding
  isConstructor
  isKind
  isSubst
  isType
  isVariable
  any
  check
  CheckIsException
  IllegalArgumentException
  isString
  isTypeOf
  isArray
  nullSubst
  singletonSubst
  typeKind
}
