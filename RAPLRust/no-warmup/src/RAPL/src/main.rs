extern crate rapl_lib;
use rapl_lib::ffi::{start_rapl, stop_rapl};

use std::env;
use std::process::Command;
extern crate shell_words;

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        eprintln!("Usage: <program> <command>");
        return;
    }

    // Combine all command line arguments into a single string
    let command_string = &args[1];

    // Use shell_words to split the command string into executable and arguments
    let command_parts = match shell_words::split(command_string) {
        Ok(parts) => parts,
        Err(err) => {
            eprintln!("Error parsing command: {}", err);
            return;
        }
    };

    // The first part is the executable, the rest are arguments
    if command_parts.is_empty() {
        eprintln!("No command provided");
        return;
    }

    let executable = &command_parts[0];
    let arguments = &command_parts[1..];

    for _ in 0..10 {
        start_rapl();

        // Create and execute the command with arguments
        let status = Command::new(executable)
            .args(arguments)
            .status()
            .expect("Failed to execute command");

        stop_rapl();

        if !status.success() {
            eprintln!("Command execution failed");
        }
    }
}
