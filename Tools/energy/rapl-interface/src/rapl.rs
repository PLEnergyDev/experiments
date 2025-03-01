use csv::{Writer, WriterBuilder};
use once_cell::sync::{Lazy, OnceCell};
use serde::Serialize;
use std::{
    env,
    fs::{File, OpenOptions},
    sync::{atomic::{AtomicUsize, Ordering}, Once},
    time::{SystemTime, UNIX_EPOCH},
    os::unix::prelude::FileExt
};
use std::path::Path;
use thiserror::Error;

#[cfg(amd)]
use crate::rapl::amd::MSR_RAPL_POWER_UNIT;
#[cfg(intel)]
use crate::rapl::intel::MSR_RAPL_POWER_UNIT;

/// Error type for RAPL operations.
#[derive(Error, Debug)]
pub enum RaplError {
    #[error("io error")]
    Io(#[from] std::io::Error),
}

// Static counter for times we started rapl
static ITERATION_COUNT: AtomicUsize = AtomicUsize::new(0);

/// Fetch the total iterations from the environment variable RAPL_ITERATIONS, defaulting to 1 iteration.
static RAPL_MAX_ITERATIONS: Lazy<usize> = Lazy::new(|| {
    env::var("RAPL_ITERATIONS")
        .ok()
        .and_then(|val| val.parse::<usize>().ok())
        .map(|iterations| iterations + 1)
        .unwrap_or(2)
});

// Store different tuples for AMD vs. Intel
#[cfg(amd)]
static mut RAPL_START: (u128, (u64, u64)) = (0, (0, 0));
#[cfg(intel)]
static mut RAPL_START: (u128, (u64, u64, u64, u64)) = (0, (0, 0, 0, 0));

// One-time initialization for RAPL
static RAPL_INIT: Once = Once::new();
static RAPL_POWER_UNITS: OnceCell<u64> = OnceCell::new();

// Global CSV writer
static mut CSV_WRITER: Option<Writer<File>> = None;
static CPU0_MSR_FD: OnceCell<File> = OnceCell::new();

/// AMD-specific constants (only compiled if `#[cfg(amd)]`).
#[cfg(amd)]
pub mod amd {
    /// Similar to Intel's MSR_RAPL_POWER_UNIT
    pub const MSR_RAPL_POWER_UNIT: u64 = 0xC0010299;
    /// Energy status for the whole socket
    pub const MSR_RAPL_PKG_ENERGY_STAT: u64 = 0xC001029B;
    /// Similar to Intel PP0_ENERGY_STATUS
    pub const AMD_MSR_CORE_ENERGY: u64 = 0xC001029A;
    /*
    const AMD_TIME_UNIT_MASK: u64 = 0xF0000;
    const AMD_ENERGY_UNIT_MASK: u64 = 0x1F00;
    const AMD_POWER_UNIT_MASK: u64 = 0xF;
    */
}

/// Intel-specific constants (only compiled if `#[cfg(intel)]`).
#[cfg(intel)]
pub mod intel {
    pub const MSR_RAPL_POWER_UNIT: u64 = 0x606;
    pub const MSR_RAPL_PKG_ENERGY_STAT: u64 = 0x611;

    pub const INTEL_MSR_RAPL_PP0: u64 = 0x639;
    pub const INTEL_MSR_RAPL_PP1: u64 = 0x641;
    pub const INTEL_MSR_RAPL_DRAM: u64 = 0x619;
    /*
    const INTEL_TIME_UNIT_MASK: u64 = 0xF000;
    const INTEL_ENGERY_UNIT_MASK: u64 = 0x1F00;
    const INTEL_POWER_UNIT_MASK: u64 = 0x0F;

    const INTEL_TIME_UNIT_OFFSET: u64 = 0x10;
    const INTEL_ENGERY_UNIT_OFFSET: u64 = 0x08;
    const INTEL_POWER_UNIT_OFFSET: u64 = 0;
    */
}

// https://github.com/greensoftwarelab/Energy-Languages/blob/master/RAPL/rapl.c#L14
fn open_msr(core: u32) -> Result<File, RaplError> {
    Ok(File::open(format!("/dev/cpu/{}/msr", core))?)
}

// https://github.com/greensoftwarelab/Energy-Languages/blob/master/RAPL/rapl.c#L38
pub fn read_msr(msr_offset: u64) -> Result<u64, RaplError> {
    let f = CPU0_MSR_FD.get_or_init(|| open_msr(0).expect("failed to open MSR"));

    let mut output_data: [u8; 8] = [0; 8];

    // TODO: Consider just seek here instead, same impl for Windows then
    f.read_at(&mut output_data, msr_offset)?;

    Ok(u64::from_le_bytes(output_data))
}

/// Public function to start RAPL measurements
pub fn start_rapl() -> i32 {
    let current_iteration = ITERATION_COUNT.fetch_add(1, Ordering::SeqCst) + 1;

    // If we've exceeded the total iterations, skip measuring and return 0
    if current_iteration > *RAPL_MAX_ITERATIONS {
        return 0;
    }

    RAPL_INIT.call_once(|| {
        // Read power unit and store it in the power units global variable
        let pwr_unit = read_msr(MSR_RAPL_POWER_UNIT).expect("failed to read RAPL power unit");
        RAPL_POWER_UNITS.get_or_init(|| pwr_unit);
    });

    // Get the current time in milliseconds since the UNIX epoch
    let timestamp_start = get_timestamp_millis();

    // Safety: RAPL_START is only accessed in this function and only from a single thread
    let rapl_registers = read_rapl_registers();
    unsafe { RAPL_START = (timestamp_start, rapl_registers) };

    // If this is the final iteration, return 0 after measuring
    if current_iteration == *RAPL_MAX_ITERATIONS {
        0
    } else {
        1
    }
}

/// Public function to stop RAPL measurements (Intel-only implementation)
#[cfg(intel)]
pub fn stop_rapl() {
    // Read the RAPL end values
    let (pp0_end, pp1_end, pkg_end, dram_end) = read_rapl_registers();

    // Current time in milliseconds since UNIX epoch
    let timestamp_end = get_timestamp_millis();

    // Load the RAPL start value
    let (timestamp_start, (pp0_start, pp1_start, pkg_start, dram_start)) = unsafe { RAPL_START };

    // Write the RAPL data to CSV
    write_to_csv(
        (
            timestamp_start,
            timestamp_end,
            pp0_start,
            pp0_end,
            pp1_start,
            pp1_end,
            pkg_start,
            pkg_end,
            dram_start,
            dram_end,
        ),
        [
            "TimeStart",
            "TimeEnd",
            "PP0Start",
            "PP0End",
            "PP1Start",
            "PP1End",
            "PkgStart",
            "PkgEnd",
            "DramStart",
            "DramEnd",
        ],
    )
    .expect("failed to write to CSV");
}

/// Public function to stop RAPL measurements (AMD-only implementation)
#[cfg(amd)]
pub fn stop_rapl() {
    // Read the RAPL end values
    let (core_end, pkg_end) = read_rapl_registers();

    // Current time in milliseconds since UNIX epoch
    let timestamp_end = get_timestamp_millis();

    // Load the RAPL start value
    let (timestamp_start, (core_start, pkg_start)) = unsafe { RAPL_START };

    // Write the RAPL data to CSV
    write_to_csv(
        (
            timestamp_start,
            timestamp_end,
            core_start,
            core_end,
            pkg_start,
            pkg_end,
        ),
        [
            "TimeStart",
            "TimeEnd",
            "CoreStart",
            "CoreEnd",
            "PkgStart",
            "PkgEnd",
        ],
    )
    .expect("failed to write to CSV");
}

/// Returns the current time in milliseconds since the UNIX epoch.
fn get_timestamp_millis() -> u128 {
    let current_time = SystemTime::now();
    let duration_since_epoch = current_time
        .duration_since(UNIX_EPOCH)
        .expect("Time went backwards");
    duration_since_epoch.as_millis()
}

/// Writes data to a CSV file, creating it if it doesn't exist yet.
fn write_to_csv<T, C, U>(data: T, columns: C) -> Result<(), std::io::Error>
where
    T: Serialize,
    C: IntoIterator<Item = U>,
    U: AsRef<[u8]>,
{
    let wtr = match unsafe { CSV_WRITER.as_mut() } {
        Some(wtr) => {
            // Already initialized, just use it.
            wtr
        }
        None => {
            // Build the CSV file path
            let file_path = format!(
                "{}_{}.csv",
                get_cpu_type(),
                RAPL_POWER_UNITS
                    .get()
                    .expect("failed to get RAPL power units")
            );

            // Check if the file exists
            let file_exists = Path::new(&file_path).exists();

            // Open in append mode
            let file = OpenOptions::new()
                .append(true)
                .create(true)
                .open(&file_path)?;

            // Create CSV writer
            let mut wtr = WriterBuilder::new().from_writer(file);

            if !file_exists || std::fs::metadata(&file_path)?.len() == 0 {
                wtr.write_record(columns)?;
            }

            // Store it globally
            unsafe { CSV_WRITER = Some(wtr) };
            unsafe { CSV_WRITER.as_mut().expect("failed to get CSV writer") }
        }
    };

    // Write the actual data row
    wtr.serialize(data)?;
    wtr.flush()?;
    Ok(())
}

/// Returns a static string identifying the CPU type based on compile-time cfg.
pub fn get_cpu_type() -> &'static str {
    #[cfg(intel)]
    {
        "Intel"
    }

    #[cfg(amd)]
    {
        "AMD"
    }
}

/// Reads the RAPL registers for AMD CPUs (only compiled if `#[cfg(amd)]`).
#[cfg(amd)]
fn read_rapl_registers() -> (u64, u64) {
    use self::amd::{AMD_MSR_CORE_ENERGY, MSR_RAPL_PKG_ENERGY_STAT};

    let core = read_msr(AMD_MSR_CORE_ENERGY).expect("failed to read CORE_ENERGY");
    let pkg = read_msr(MSR_RAPL_PKG_ENERGY_STAT).expect("failed to read RAPL_PKG_ENERGY_STAT");

    (core, pkg)
}

/// Reads the RAPL registers for Intel CPUs (only compiled if `#[cfg(intel)]`).
#[cfg(intel)]
fn read_rapl_registers() -> (u64, u64, u64, u64) {
    use self::intel::{
        INTEL_MSR_RAPL_DRAM, INTEL_MSR_RAPL_PP0, INTEL_MSR_RAPL_PP1, MSR_RAPL_PKG_ENERGY_STAT,
    };

    let pp0 = read_msr(INTEL_MSR_RAPL_PP0).expect("failed to read PP0");
    let pp1 = read_msr(INTEL_MSR_RAPL_PP1).expect("failed to read PP1");
    let pkg = read_msr(MSR_RAPL_PKG_ENERGY_STAT).expect("failed to read RAPL_PKG_ENERGY_STAT");
    let dram = read_msr(INTEL_MSR_RAPL_DRAM).expect("failed to read DRAM");

    (pp0, pp1, pkg, dram)
}
