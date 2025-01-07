use sysinfo::{CpuExt, System, SystemExt};

fn main() {
    let sys = System::new_all();
    let cpu = sys.cpus().first().expect("failed getting CPU").vendor_id();
    match cpu {
        "GenuineIntel" => println!("cargo:rustc-cfg=intel"),
        "AuthenticAMD" => println!("cargo:rustc-cfg=amd"),
        _ => {
            panic!("unknown CPU detected: {}", cpu);
        }
    };
}
