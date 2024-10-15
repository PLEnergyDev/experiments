extern crate rapl_lib;

use std::env;
use rapl_lib::ffi::start_rapl;
use rapl_lib::ffi::stop_rapl;

fn division_loop(m: i32) -> f64 {
    let mut sum = 0.0;
    let mut n = 0;
    
    while sum < m as f64 {
        n += 1;
        sum += 1.0 / n as f64;
    }
    
    n as f64
}

fn main() {
    let args: Vec<String> = env::args().collect();
    
    if args.len() < 3 {
        eprintln!("Usage: {} <M>", args[0]);
        return;
    }

    let counter = args[1].parse().expect("Please provide a valid integer.");
    for _ in 0..counter {
        start_rapl();
        let m: i32 = args[2].parse().expect("Please provide a valid integer.");

        for i in 0..10 {
            let result = division_loop(m);
            println!("{}", result);
        }
        stop_rapl();
    }
}
