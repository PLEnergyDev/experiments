const os = require("os");

const runCount = process.argv[2];
const sleep_time = process.argv[3];
const libPath = os.platform() == "win32" ?
  "target\\release\\rapl_lib.dll" :
  "target/release/librapl_lib.so"

const koffi = require('koffi');
const lib = koffi.load(libPath);

const start = lib.func('int start_rapl()');
const stop = lib.func('void stop_rapl()');

// test method
// taken from https://stackoverflow.com/questions/951021/what-is-the-javascript-version-of-sleep
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// wrapping the benchmark in a function to allow for await
async function benchmark(){
  for (let i = 0; i < runCount; i++) {
    start();

    await sleep(sleep_time * 1000);

    stop();
  }
} 

// running benchmark
benchmark();
