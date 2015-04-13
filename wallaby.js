module.exports = function(wallaby) {
  return {
    'files': [
      'src/*.js',
      'src/*.coffee'
    ],
    'tests': [
      'test/*.js',
      'test/*.coffee'
    ],
    env: {
      type: 'node'
    },
    compilers: {
      //'**/*.js': wallaby.compilers.babel({
      //  babel: babel,
      //  // other babel options
      //  stage: 0    // https://babeljs.io/docs/usage/experimental/
      //}),
      //
      //'**/*.ts': wallaby.compilers.typeScript({
      //  // TypeScript compiler specific options
      //  // https://github.com/Microsoft/TypeScript/blob/master/src/compiler/types.ts#L1584
      //}),

      '**/*.coffee': wallaby.compilers.coffeeScript({
        // CoffeeScript compiler specific options
      })
    }
  };
};
