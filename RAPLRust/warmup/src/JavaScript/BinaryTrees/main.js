/* The Computer Language Benchmarks Game
   http://benchmarksgame.alioth.debian.org/
   contributed by Isaac Gouy 
   *reset* 
*/
// finding path depending on OS
const koffi = require('koffi');
const libPath = "../../rapl-interface/target/release/librapl_lib.so"
// loading library
const lib = koffi.load(libPath);
// loading functions
const start = lib.func('int start_rapl()');
const stop = lib.func('void stop_rapl()');
const count = process.argv[2];


function TreeNode(left, right, item) {
    this.left = left;
    this.right = right;
}

TreeNode.prototype.itemCheck = function () {
    if (this.left == null) return 1;
    else return 1 + this.left.itemCheck() + this.right.itemCheck();
}

function bottomUpTree(depth) {
    if (depth > 0) {
        return new TreeNode(
            bottomUpTree(depth - 1)
            , bottomUpTree(depth - 1)
        );
    }
    else {
        return new TreeNode(null, null);
    }
}


for (let counter = 0; counter < count; counter++) {
    start();
    var minDepth = 4;
    var n = +process.argv[3];
    var maxDepth = Math.max(minDepth + 2, n);
    var stretchDepth = maxDepth + 1;

    var check = bottomUpTree(stretchDepth).itemCheck();
    console.log("stretch tree of depth " + stretchDepth + "\t check: " + check);

    var longLivedTree = bottomUpTree(maxDepth);
    for (var depth = minDepth; depth <= maxDepth; depth += 2) {
        var iterations = 1 << (maxDepth - depth + minDepth);

        check = 0;
        for (var i = 1; i <= iterations; i++) {
            check += bottomUpTree(depth).itemCheck();
        }
        console.log(iterations + "\t trees of depth " + depth + "\t check: " + check);
    }
    console.log("long lived tree of depth " + maxDepth + "\t check: " 
        + longLivedTree.itemCheck());
    stop();
}