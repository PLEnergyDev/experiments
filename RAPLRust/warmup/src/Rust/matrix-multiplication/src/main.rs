// The Computer Language Benchmarks Game
// https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
//
// contributed by [original contributor's name]

use std::env;
use rapl_lib::ffi::start_rapl;
use rapl_lib::ffi::stop_rapl;

struct Matrix {
    rows: usize,
    cols: usize,
    data: Vec<f64>,
}

impl Matrix {
    fn new(rows: usize, cols: usize) -> Matrix {
        let mut data = vec![0.0; rows * cols];
        for i in 0..rows {
            for j in 0..cols {
                data[cols * i + j] = (i + j) as f64;
            }
        }
        Matrix { rows, cols, data }
    }
}

fn matrix_multiplication(a: &Matrix, b: &Matrix, r: &mut Matrix) -> f64 {
    let mut sum = 0.0;
    for row_index in 0..r.rows {
        for col_index in 0..r.cols {
            sum = 0.0;
            for k in 0..a.cols {
                sum += a.data[row_index * a.cols + k] * b.data[k * b.cols + col_index];
            }
            r.data[row_index * r.cols + col_index] = sum;
        }
    }
    sum
}

fn initialize() {}

fn run_benchmark(rows: usize, cols: usize) {
    let mut r = Matrix {
        rows,
        cols,
        data: vec![0.0; rows * cols],
    };
    let a = Matrix::new(rows, cols);
    let b = Matrix::new(rows, cols);
    let result = matrix_multiplication(&a, &b, &mut r);
    println!("{}", result);
}

fn cleanup() {}

fn main() {
    let args: Vec<String> = env::args().collect();
    let iterations: usize = args[1].parse().expect("");
    let rows: usize = args[2].parse().expect("Please provide a valid integer for rows.");
    let cols: usize = args[3].parse().expect("Please provide a valid integer for cols.");
    for i in 0..iterations {
        initialize();
        start_rapl();
        for _ in 0..100 {
            run_benchmark(rows, cols);
        }
        stop_rapl();
        cleanup();
    }
}
