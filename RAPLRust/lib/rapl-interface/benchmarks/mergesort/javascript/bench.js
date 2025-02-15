const os = require("os");
const fs = require("fs");

// getting arguments
let mergeParam = fs.readFileSync(process.argv[3]).toString();

// formatting input into a list of numbers
mergeParam = mergeParam.replace("[", "").replace("]", "").split(",").map(Number);
const runCount = process.argv[2];

// finding path depending on OS
const libPath = os.platform() == "win32" ?
    "target\\release\\rapl_lib.dll" :
    "target/release/librapl_lib.so"

// test method from Rosetta Code
function mergeSortInPlaceFast(v) {
    sort(v, 0, v.length, v.slice());

    function sort(v, lo, hi, t) {
        let n = hi - lo;
        if (n <= 1) {
            return;
        }
        let mid = lo + Math.floor(n / 2);
        sort(v, lo, mid, t);
        sort(v, mid, hi, t);
        for (let i = lo; i < hi; i++) {
            t[i] = v[i];
        }
        let i = lo, j = mid;
        for (let k = lo; k < hi; k++) {
            if (i < mid && (j >= hi || t[i] < t[j])) {
                v[k] = t[i++];
            } else {
                v[k] = t[j++];
            }
        }
    }
}

// loading library
const koffi = require('koffi');
const lib = koffi.load(libPath);

// loading functions
const start = lib.func('int start_rapl()');
const stop = lib.func('void stop_rapl()');

// running benchmark
for (let i = 0; i < runCount; i++) {

    let toBeSorted = Array.from(mergeParam);
    start();

    mergeSortInPlaceFast(toBeSorted);

    stop();

    if (toBeSorted.length < 42){
        console.log(toBeSorted);
    }
}
