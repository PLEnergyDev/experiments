const os = require("os");

// getting arguments
const runCount = process.argv[2];
const fibParam = process.argv[3];

// finding path depending on OS
const libPath = os.platform() == "win32" ?
  "target\\release\\rapl_lib.dll" :
  "target/release/librapl_lib.so"

// test method from Rosetta code
function fib(n) {
  return n<2?n:fib(n-1)+fib(n-2);
}

// loading library
const koffi = require('koffi');
const lib = koffi.load(libPath);

// loading functions
const start = lib.func('int start_rapl()');
const stop = lib.func('void stop_rapl()');

// running benchmark
for (let i = 0; i < runCount; i++) {
  start();

  let result = fib(fibParam);

  stop();
  if (result < 42){
      console.log(result);
  }
}
