use std::env;
use rapl_lib::ffi::start_rapl;
use rapl_lib::ffi::stop_rapl;

fn initialize() {}

fn run_benchmark(n: usize) {
    for _ in 0..20000 {
        let result = polynomial_evaluation(n);
        println!("{}", result);
    }
}

fn cleanup() {}

fn init_cs(n: usize) -> Vec<f64> {
    let mut cs: Vec<f64> = vec![0.0; n];
    for i in 0..n {
        cs[i] = 1.1 * i as f64;
        if i % 3 == 0 {
            cs[i] *= -1.0;
        }
    }
    cs
}

fn polynomial_evaluation(n: usize) -> f64 {
    let cs: Vec<f64> = init_cs(n);
    let mut res: f64 = 0.0;
    for i in 0..n {
        res = cs[i] + 5.0 * res;
    }
    res
}

fn main() {
    let args: Vec<String> = env::args().collect();
    let iterations = std::env::args().nth(1)
        .and_then(|n| n.parse().ok())
        .unwrap_or(1);
    let n: usize = args[2].parse().expect("Please provide a valid integer for n.");
    for _ in 0..iterations {
        initialize();
        start_rapl();
        run_benchmark(n);
        stop_rapl();
        cleanup();
    }
}
