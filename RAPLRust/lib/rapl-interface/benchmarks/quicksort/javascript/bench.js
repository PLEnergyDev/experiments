const os = require("os");
const fs = require("fs");

// getting arguments
let data = fs.readFileSync(process.argv[3]).toString();
// formatting input into a list of numbers
const sortParam = data.replace("[", "").replace("]", "").split(",").map(Number);
const runCount = process.argv[2];

// finding path depending on OS
const libPath = os.platform() == "win32"?
  "target\\release\\rapl_lib.dll":
  "target/release/librapl_lib.so"

// test method from Rosetta Code
function sort(array, less) {

    function swap(i, j) {
      var t = array[i];
      array[i] = array[j];
      array[j] = t;
    }
  
    function quicksort(left, right) {   
      if (left < right) {
        var pivot = array[left + Math.floor((right - left) / 2)],
            left_new = left,
            right_new = right;
  
        do {
          while (less(array[left_new], pivot)) {
            left_new += 1;
          }
          while (less(pivot, array[right_new])) {
            right_new -= 1;
          }
          if (left_new <= right_new) {
            swap(left_new, right_new);
            left_new += 1;
            right_new -= 1;
          }
        } while (left_new <= right_new);
  
        quicksort(left, right_new);
        quicksort(left_new, right);
  
      }
    }
  
    quicksort(0, array.length - 1);
  
    return array;
  }

// loading library
const koffi = require('koffi');
const lib = koffi.load(libPath);

// loading functions
const start = lib.func('int start_rapl()');
const stop = lib.func('void stop_rapl()');

// running benchmark
for (let i = 0; i < runCount; i++){

    start();

    let sorted = sort(sortParam, function(a, b) {return a < b});

    stop();
    
    // stopping compiler optimizations
    if (sorted.length < 42){
        console.log(sorted);
    }
}
