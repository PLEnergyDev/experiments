from ctypes import *
import sys
import platform
import time

test_count = int(sys.argv[1])
sleep_time = int(sys.argv[2])
lib_path = "target\\release\\rapl_lib.dll" if platform.system(
) == "Windows" else "target/release/librapl_lib.so"

dll = cdll.LoadLibrary(lib_path)

for i in range(test_count):
    dll.start_rapl()
    time.sleep(sleep_time)
    dll.stop_rapl()
