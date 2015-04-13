var assert = require('assert');

var src = require('../src/kinds');

var expectError = function(err, f) {
  var errCaught = false;
  try {
    f();
  } catch (e) {
    if (e instanceof err) {
      errCaught = true;
    } else {
      throw e;
    }
  }
  if (!errCaught) {
    assert.fail("", err, "No error thrown");
  }
};

var expectIllegalArgumentException = function(f) {
  return expectError(src.IllegalArgumentException, f);
};

var expectCheckIsException = function(f) {
  return expectError(src.CheckIsException, f);
};

describe('isTypeOf', function() {
  it('should reject undefined', function() {
    expectIllegalArgumentException(function() { return src.isTypeOf(undefined); });
  });
  it('should reject integers', function() {
    expectIllegalArgumentException(function() { return src.isTypeOf(7); });
  });
  it('should reject objects', function() {
    expectIllegalArgumentException(function() { return src.isTypeOf({})});
  });
  it('should reject arrays', function() {
    expectIllegalArgumentException(function() { return src.isTypeOf([])});
  });
  it('should accept strings', function() {
    src.isTypeOf('string');
  });
});

describe('isString', function() {
  var isString = function(val) {
    return src.check(src.isString, val);
  };
  it('should accept hello', function() {
    isString('hello');
  });
  it('should accept the empty string', function() {
    isString('');
  });
  it('should accept a number in a string', function() {
    isString('7');
  });
  it('should reject a number', function() {
    expectCheckIsException(function() { return isString(7); });
  });
  it('should reject undefined', function() {
    expectCheckIsException(function() { return isString(undefined); });
  });
});

describe('adt', function() {
  var isMaybe = src.adt("maybe", function() {
    return {
      Nothing: {},
      Just: { value: src.any }
    };
  });
  it('should accept nothing', function() {
    //src.check(isMaybe, { Nothing: {}});
  });
});

describe('adt', function() {
  it('should reject non-objects', function() {
    expectCheckIsException(function() {
      var isMyType = src.adt("myType", "badSchema");
      src.check(isMyType, undefined);
    });
  });
});
