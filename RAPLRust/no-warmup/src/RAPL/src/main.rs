
extern crate rapl_lib;
use rapl_lib::ffi::start_rapl;
use rapl_lib::ffi::stop_rapl;

use std::env;
use std::process::Command;


fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        eprintln!("Usage: <program> <command>");
        return;
    }

    let command = &args[1];

    for _ in 0..10 {
        start_rapl();

        let status = Command::new(command)
            .status()
            .expect("Failed to execute command");

        stop_rapl();
        if !status.success() {
            eprintln!("Command execution failed");
        }
    }
}
