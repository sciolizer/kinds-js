assert = require 'assert'

src = require '../src/testing'

star = {Star:{}}
func = (left, right) -> {Function:{left,right}}
starToStar = func(star,star)
maybeType = {Constructor:{constructor:{Constructor:{name:"Maybe",kind:func(star,star)}}}}
integerType = {Constructor:{constructor:{Constructor:{name:"Integer",kind:star}}}}
xVariable = {Variable:{name:"x",kind:star}}
xVariableType = {Variable:{variable:xVariable}}

expectError = (err, f) ->
  errCaught = false
  try
    f()
  catch e
    if e instanceof err
      errCaught = true
    else
      throw e
  if !errCaught
    assert.fail "", err, "No error thrown"

expectIllegalArgumentException = (f) ->
  expectError src.IllegalArgumentException, f

expectCheckIsException = (f) ->
  expectError src.CheckIsException, f

describe 'isTypeOf', ->
  eiae = (val) -> expectIllegalArgumentException(-> src.isTypeOf val)
  it 'should reject undefined', -> eiae undefined
  it 'should reject integers', -> eiae 7
  it 'should reject objects', -> eiae {}
  it 'should reject arrays', -> eiae []
  it 'should accept strings', ->
    src.isTypeOf('string')

describe 'isString', ->
  isString = (val) ->
    src.check src.isString, val
  ecie = (val) -> expectCheckIsException(-> isString val)
  it 'should accept hello', -> isString 'hello'
  it 'should accept the empty string', -> isString ''
  it 'should accept a number in a string', -> isString '7'
  it 'should reject a number', -> ecie 7
  it 'should reject undefined', -> ecie undefined

describe 'adt maybe', ->
  isMaybe = src.adt "maybe", ->
    {
    Nothing: {}
    Just: {value: src.any}
    }
  ecie = (val) -> expectCheckIsException(-> src.check isMaybe, val)
  it 'should accept nothing', -> src.check isMaybe, {Nothing: {}}
  it 'should accept just an integer', -> src.check isMaybe, {Just: {value: 7}}
  it 'should reject an empty object', -> ecie {}
  it 'should reject undefined', -> ecie undefined
  it 'should reject a string', -> ecie 'hello'
  it 'should reject true and false', ->
    ecie true
    ecie false
  it 'should reject an array', -> ecie []
  it 'should reject a function', -> ecie ->
  it 'should reject an object with the wrong constructor', -> ecie {value: 7}
  it 'should reject an object with too many constructors', -> ecie {Nothing: {}, Just: {value: 7}}
  it 'should reject an object with too few fields', -> ecie {Just: {}}
  it 'should reject an object with the wrong field', -> ecie {Just: {hello: 8}}
  it 'should reject an object with too many fields', -> ecie {Just: {value: 8, hello: 9}}

describe 'adt schema', ->
  it 'should reject a string as a schema', ->
    expectCheckIsException -> src.adt('myType', 'badSchema')
  it 'should reject undefined as a schema', ->
    expectCheckIsException -> src.adt('myType', undefined)

describe 'isKind', ->
  it 'should accept *', -> src.isKind star
  it 'should accept * -> *', -> src.isKind starToStar
  it 'should reject * -> obj', ->
    expectCheckIsException -> src.isKind {Function: {left: {Star: {}}, right: {}}}

describe 'isVariable', ->
  it 'should accept x', -> src.isVariable xVariable

describe 'isConstructor', ->
  it 'should accept Just', -> src.isConstructor {Constructor: {name: "Just", kind: starToStar}}

describe 'isType', ->
  it 'should accept x', -> src.isType xVariableType
  it 'should accept Integer', -> src.isType integerType
  it 'should accept Maybe(Integer)', ->
    maybeType = {Constructor: {constructor: {Constructor: {name: "Maybe", kind: starToStar}}}}
    src.isType {Apply: {left: maybeType, right: integerType}}

describe 'listFunctions', ->
  it 'should have a member', ->
    [].indexOf('h')
    console.log "[].indexOf('h') = ", [].indexOf('h')

describe 'checkReturn', ->
  it 'should accept returning a string', ->
    src.checkReturn src.isString, ->
      "hello"
  it 'should reject returning undefined', ->
    expectCheckIsException -> src.checkReturn src.isString, ->

describe 'isArray', ->
  acceptArrayOfStrings = (val) -> src.check(src.isArray(src.isString), val)
  rejectArrayOfStrings = (val) -> expectCheckIsException -> acceptArrayOfStrings(val)
  it 'should accept an array of strings', ->
    acceptArrayOfStrings ["hello", "goodbye"]
  it 'should accept an empty array', ->
    acceptArrayOfStrings []
  it 'should reject undefined', ->
    rejectArrayOfStrings undefined
  it 'should reject an object', ->
    rejectArrayOfStrings {}
  it 'should reject an array of ints', ->
    rejectArrayOfStrings [5]
  it 'should reject a heterogenous array', ->
    rejectArrayOfStrings ["hello", 7]

describe 'nullSubst', ->
  it 'should be an array', ->
    src.check(src.isArray(src.any), src.nullSubst())

describe 'eqKind', ->
  expectEqual = (left, right) ->
    assert(src.eqKind(left, right))
  expectUnequal = (left, right) ->
    assert.equal(src.eqKind(left,right), false)
  it 'should say * == *', ->
    expectEqual star, star
  it 'should say (* -> *) == (* -> *)', ->
    expectEqual(starToStar,starToStar)
  it 'should say ((* -> *) -> *) == ((* -> *) -> *)', ->
    expectEqual(func(starToStar,star),func(starToStar,star))
  it 'should say * != * -> *', ->
    expectUnequal(star, starToStar)
  it 'should say * -> * != *', ->
    expectUnequal(starToStar, star)
  it 'should say * -> * != * -> * -> *', ->
    expectUnequal(starToStar, func(star,starToStar))

describe 'typeKind', ->
  assertEqualKinds = (left, right) ->
    assert(src.eqKind(left,right))
  it 'should say the kind of x is a star', ->
    assertEqualKinds(src.typeKind(xVariableType),star)
  it 'should say the kind of maybe is * -> *', ->
    assertEqualKinds(src.typeKind(maybeType), starToStar)
  it 'should say the kind of maybe int is *', ->
    assertEqualKinds(src.typeKind({Apply:{left:maybeType,right:integerType}}), star)

describe 'isBinding', ->
  it 'should accept x as an int', ->
    src.check src.isBinding, {Binding:{variable:xVariable,type:integerType}}

describe 'isSubst', ->
  it 'should accept my bindings', ->
    src.check src.isSubst, [{Binding:{variable:xVariable,type:integerType}}]

describe 'singletonSubst', ->
  it 'should accept x as an integer', ->
    src.singletonSubst xVariable, integerType

describe 'typeVariables', ->
  it 'should return a singleton for a variable', ->
    assert.deepEqual(src.typeVariables(xVariableType), [xVariable])
  it 'should return any variables it encounters', ->
    assert.deepEqual(src.typeVariables({Apply:{left:maybeType,right:xVariableType}}, [xVariable]), [xVariable])
  it 'should return the union of variables in an applied type', ->
    tvs = src.typeVariables({Apply:{left:{Apply:{left:{Constructor:{constructor:{Constructor:{name:"Map",kind:func(star,starToStar)}}}},right:xVariableType}},right:xVariableType}})
    assert.deepEqual tvs, [xVariable]
  it 'should find not variables in a constructor type', ->
    assert.deepEqual(src.typeVariables(integerType), [])

#describe 'bindVariable', ->
#  it 'should return the empty substitution for binding a variable to itself', ->
#    subst = src.bindVariable {Variable:{name:"x",kind:star}}, {Variable:{variable:{Variable:{name:"x",kind:star}}}}
#    assert.deepEqual subst, []
