use std::env;
use rapl_lib::ffi::start_rapl;
use rapl_lib::ffi::stop_rapl;

fn initialize() {
    // Initialization phase (nothing specific to initialize here)
}

fn run_benchmark(m: i32) -> f64 {
    let mut sum = 0.0;
    let mut n = 0;
    
    while sum < m as f64 {
        n += 1;
        sum += 1.0 / n as f64;
    }
    
    n as f64
}

fn cleanup() {
    // Cleanup phase (nothing specific to cleanup here)
}

fn main() {
    let args: Vec<String> = env::args().collect();
    let iterations: i32 = args[1].parse().expect("Please provide a valid integer.");
    let m: i32 = args[2].parse().expect("Please provide a valid integer.");

    for _ in 0..iterations {
        initialize();
        start_rapl();
        for _ in 0..10 {
            let result = run_benchmark(m); 
            println!("{}", result);
        }
        stop_rapl();
        cleanup();
    }
}
