# NOTE MUST BE CALLED FROM ROOT
from ctypes import *
import sys
import platform

# used in test method
from heapq import merge

def readFile(path):
    with open(path, "r") as file:
        return file.read()

merge_param = readFile(sys.argv[2])
# formatting merge_param into a list of integers
merge_param = merge_param.replace("[", "").replace("]", "").split(",")
merge_param = [int(i) for i in merge_param]
test_count = int(sys.argv[1])
lib_path = "target\\release\\rapl_lib.dll" if platform.system(
) == "Windows" else "target/release/librapl_lib.so"

# test method from Rosetta Code
def merge_sort(m):
    if len(m) <= 1:
        return m

    middle = len(m) // 2
    left = m[:middle]
    right = m[middle:]

    left = merge_sort(left)
    right = merge_sort(right)
    return list(merge(left, right))


# load lib
dll = cdll.LoadLibrary(lib_path)

# running benchmark
for i in range(test_count):
    # start recording
    dll.start_rapl()

    # run test
    result = merge_sort(merge_param)

    # stop recording
    dll.stop_rapl()
    if len(result) < 42:
        print(result)
