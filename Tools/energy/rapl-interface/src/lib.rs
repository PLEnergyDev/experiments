mod rapl;

#[no_mangle]
pub extern "C" fn start_rapl() -> i32 {
    return rapl::start_rapl();
}

#[no_mangle]
pub extern "C" fn stop_rapl() {
    rapl::stop_rapl();
}
