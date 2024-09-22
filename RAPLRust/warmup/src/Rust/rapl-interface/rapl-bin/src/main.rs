use anyhow::Result;
use rapl_lib::ffi::{start_rapl, stop_rapl};
use std::{thread, time::Duration};

fn main() -> Result<()> {
    // Call start_rapl() to initialize the RAPL driver on Windows
    start_rapl();

    loop {
        // Get a RAPL measurement and write it to the CSV file
        stop_rapl();

        // Sleep until the next measurement
        thread::sleep(Duration::from_millis(100));
    }
}

/*
// AMD unit masks
let time_unit = ((output_number & AMD_TIME_UNIT_MASK) >> 16) as f64;
let energy_unit = ((output_number & AMD_ENERGY_UNIT_MASK) >> 8) as f64;
let power_unit = (output_number & AMD_POWER_UNIT_MASK) as f64;
println!(
    "time_unit: {}, energy_unit: {}, power_unit: {}",
    time_unit, energy_unit, power_unit
);

// AMD converted unit masks
let time_unit_d = time_unit.powf(0.5);
let energy_unit_d = energy_unit.powf(0.5);
let power_unit_d = power_unit.powf(0.5);
println!(
    "time_unit_d: {}, energy_unit_d: {}, power_unit_d: {}",
    time_unit_d, energy_unit_d, power_unit_d
);
*/
