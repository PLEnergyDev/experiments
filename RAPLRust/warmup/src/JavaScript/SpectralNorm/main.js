// The Computer Language Benchmarks Game
// http://benchmarksgame.alioth.debian.org/
//
// contributed by Ian Osgood
// modified for Node.js by Isaac Gouy 
// finding path depending on OS
const koffi = require('koffi');
const libPath = "../../rapl-interface/target/release/librapl_lib.so"
// loading library
const lib = koffi.load(libPath);
// loading functions
const start = lib.func('int start_rapl()');
const stop = lib.func('void stop_rapl()');
const count = process.argv[2];
function A(i, j) {
    return 1 / ((i + j) * (i + j + 1) / 2 + i + 1);
}

function Au(u, v) {
    for (var i = 0; i < u.length; ++i) {
        var t = 0;
        for (var j = 0; j < u.length; ++j)
            t += A(i, j) * u[j];
        v[i] = t;
    }
}

function Atu(u, v) {
    for (var i = 0; i < u.length; ++i) {
        var t = 0;
        for (var j = 0; j < u.length; ++j)
            t += A(j, i) * u[j];
        v[i] = t;
    }
}

function AtAu(u, v, w) {
    Au(u, w);
    Atu(w, v);
}

function spectralnorm(n) {
    var i, u = new Float64Array(n), v = new Float64Array(n), w = new Float64Array(n), vv = 0, vBv = 0;
    for (i = 0; i < n; ++i) {
        u[i] = 1; v[i] = w[i] = 0; 
    }
    for (i = 0; i < 10; ++i) {
        AtAu(u, v, w);
        AtAu(v, u, w);
    }
    for (i = 0; i < n; ++i) {
        vBv += u[i] * v[i];
        vv += v[i] * v[i];
    }
    return Math.sqrt(vBv / vv);
}
for (let counter = 0; counter < count; counter++) {
    start();

    console.log(spectralnorm(+process.argv[3]).toFixed(9));
    stop();
}