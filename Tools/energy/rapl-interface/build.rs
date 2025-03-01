use sysinfo::System;

fn main() {
    println!("cargo:rustc-check-cfg=cfg(intel)");
    println!("cargo:rustc-check-cfg=cfg(amd)");

    let mut sys = System::new();
    sys.refresh_cpu_all();

    let cpu_vendor = sys
        .cpus()
        .first()
        .map(|cpu| cpu.vendor_id().to_string())
        .unwrap_or_else(|| {
            eprintln!("Warning: Failed to detect CPU vendor. Using default configuration.");
            "Unknown".to_string()
        });

    println!("Detected CPU vendor: {}", cpu_vendor);

    match cpu_vendor.as_str() {
        "GenuineIntel" => println!("cargo:rustc-cfg=intel"),
        "AuthenticAMD" => println!("cargo:rustc-cfg=amd"),
        _ => {
            eprintln!("Warning: Unknown CPU detected ({}). Defaulting to generic configuration.", cpu_vendor);
            println!("cargo:rustc-cfg=generic_cpu");
        }
    };
}
