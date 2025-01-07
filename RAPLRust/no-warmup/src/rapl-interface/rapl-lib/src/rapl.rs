use csv::{Writer, WriterBuilder};
use once_cell::sync::OnceCell;
use serde::Serialize;
use std::{
    fs::{File, OpenOptions},
    sync::Once,
    time::{SystemTime, UNIX_EPOCH},
};
use thiserror::Error;

// Use the OS specific implementation
#[cfg(target_os = "linux")]
pub mod os_linux;
#[cfg(target_os = "windows")]
pub mod os_windows;

// Import the OS specific functions
#[cfg(target_os = "linux")]
use self::os_linux::{read_msr, start_rapl_impl};
#[cfg(target_os = "windows")]
use self::os_windows::{read_msr, start_rapl_impl};

#[derive(Error, Debug)]
pub enum RaplError {
    #[error("io error")]
    Io(#[from] std::io::Error),
    #[cfg(target_os = "windows")]
    #[error("windows error")]
    Windows(#[from] windows::core::Error),
}

#[cfg(amd)]
static mut RAPL_START: (u128, (u64, u64)) = (0, (0, 0));

#[cfg(intel)]
static mut RAPL_START: (u128, (u64, u64, u64, u64)) = (0, (0, 0, 0, 0));

static RAPL_INIT: Once = Once::new();
static RAPL_POWER_UNITS: OnceCell<u64> = OnceCell::new();
static mut CSV_WRITER: Option<Writer<File>> = None;

pub fn start_rapl() {
    // Run the OS specific start_rapl_impl function
    start_rapl_impl();

    RAPL_INIT.call_once(|| {
        // Import the MSR RAPL power unit constants per CPU type
        #[cfg(amd)]
        use crate::rapl::amd::MSR_RAPL_POWER_UNIT;
        #[cfg(intel)]
        use crate::rapl::intel::MSR_RAPL_POWER_UNIT;

        // Read power unit and store it in the power units global variable
        let pwr_unit = read_msr(MSR_RAPL_POWER_UNIT).expect("failed to read RAPL power unit");
        RAPL_POWER_UNITS.get_or_init(|| pwr_unit);
    });

    // Get the current time in milliseconds since the UNIX epoch
    let timestamp_start = get_timestamp_millis();

    // Safety: RAPL_START is only accessed in this function and only from a single thread
    let rapl_registers = read_rapl_registers();
    unsafe { RAPL_START = (timestamp_start, rapl_registers) };
}

#[cfg(intel)]
pub fn stop_rapl() {
    // Read the RAPL end values
    let (pp0_end, pp1_end, pkg_end, dram_end) = read_rapl_registers();

    // Get the current time in milliseconds since the UNIX epoch
    let timestamp_end = get_timestamp_millis();

    // Load in the RAPL start value
    let (timestamp_start, (pp0_start, pp1_start, pkg_start, dram_start)) = unsafe { RAPL_START };

    // Write the RAPL start and end values to the CSV
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

#[cfg(amd)]
pub fn stop_rapl() {
    // Read the RAPL end values
    let (core_end, pkg_end) = read_rapl_registers();

    // Get the current time in milliseconds since the UNIX epoch
    let timestamp_end = get_timestamp_millis();

    // Load in the RAPL start value
    let (timestamp_start, (core_start, pkg_start)) = unsafe { RAPL_START };

    // Write the RAPL start and end values to the CSV
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

fn get_timestamp_millis() -> u128 {
    let current_time = SystemTime::now();
    let duration_since_epoch = current_time
        .duration_since(UNIX_EPOCH)
        .expect("Time went backwards");
    duration_since_epoch.as_millis()
}

fn write_to_csv<T, C, U>(data: T, columns: C) -> Result<(), std::io::Error>
where
    T: Serialize,
    C: IntoIterator<Item = U>,
    U: AsRef<[u8]>,
{
    let wtr = match unsafe { CSV_WRITER.as_mut() } {
        Some(wtr) => wtr,
        None => {
            // Open the file to write to CSV. First argument is CPU type, second is RAPL power units
            let file = OpenOptions::new().append(true).create(true).open(format!(
                "{}_{}.csv",
                get_cpu_type(),
                RAPL_POWER_UNITS
                    .get()
                    .expect("failed to get RAPL power units")
            ))?;

            // Create the CSV writer
            let mut wtr = WriterBuilder::new().from_writer(file);

            // Write the column names
            wtr.write_record(columns)?;

            // Store the CSV writer in a static variable
            unsafe { CSV_WRITER = Some(wtr) };

            // Return a mutable reference to the CSV writer
            unsafe { CSV_WRITER.as_mut().expect("failed to get CSV writer") }
        }
    };

    // Write the data to the CSV and flush it
    wtr.serialize(data)?;
    wtr.flush()?;

    Ok(())
}

// Get the CPU type based on the compile time configuration
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

#[cfg(amd)]
fn read_rapl_registers() -> (u64, u64) {
    use self::amd::{AMD_MSR_CORE_ENERGY, MSR_RAPL_PKG_ENERGY_STAT};

    let core = read_msr(AMD_MSR_CORE_ENERGY).expect("failed to read CORE_ENERGY");
    let pkg = read_msr(MSR_RAPL_PKG_ENERGY_STAT).expect("failed to read RAPL_PKG_ENERGY_STAT");

    (core, pkg)
}

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

#[cfg(amd)]
pub mod amd {
    /*
    https://lore.kernel.org/lkml/20180817163442.10065-2-calvin.walton@kepstin.ca/

    "A notable difference from the Intel implementation is that AMD reports
    the "Cores" energy usage separately for each core, rather than a
    per-package total"
     */

    pub const MSR_RAPL_POWER_UNIT: u64 = 0xC0010299; // Similar to Intel MSR_RAPL_POWER_UNIT
    pub const MSR_RAPL_PKG_ENERGY_STAT: u64 = 0xC001029B; // Similar to Intel PKG_ENERGY_STATUS (This is for the whole socket)

    pub const AMD_MSR_CORE_ENERGY: u64 = 0xC001029A; // Similar to Intel PP0_ENERGY_STATUS (PP1 is for the GPU)

    /*
    const AMD_TIME_UNIT_MASK: u64 = 0xF0000;
    const AMD_ENERGY_UNIT_MASK: u64 = 0x1F00;
    const AMD_POWER_UNIT_MASK: u64 = 0xF;
    */
}

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
