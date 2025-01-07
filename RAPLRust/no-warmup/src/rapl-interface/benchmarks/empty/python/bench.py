from ctypes import *
import sys
import platform

test_count = int(sys.argv[1])
lib_path = "target\\release\\rapl_lib.dll" if platform.system(
) == "Windows" else "target/release/librapl_lib.so"

dll = cdll.LoadLibrary(lib_path)

for i in range(test_count):
    dll.start_rapl()
    dll.stop_rapl()
