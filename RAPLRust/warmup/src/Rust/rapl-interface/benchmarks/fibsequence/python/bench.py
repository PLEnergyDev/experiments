# NOTE MUST BE CALLED FROM ROOT

from ctypes import *
import sys
import platform

test_count = int(sys.argv[1])
fib_param = int(sys.argv[2])
lib_path = "target\\release\\rapl_lib.dll" if platform.system(
) == "Windows" else "target/release/librapl_lib.so"

# test method from Rosetta code
def fibRec(n):
    if n < 2:
        return n
    else:
        return fibRec(n-1) + fibRec(n-2)


# load lib
dll = cdll.LoadLibrary(lib_path)

# running benchmark
for i in range(test_count):
    # start recording
    dll.start_rapl()

    # run test
    result = fibRec(fib_param)

    # stop recording
    dll.stop_rapl()
    
    if result < 42:
        print(result)
