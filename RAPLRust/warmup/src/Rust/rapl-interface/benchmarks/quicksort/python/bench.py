# NOTE MUST BE CALLED FROM ROOT

from ctypes import *
import sys
import platform

def readFile(path):
    with open(path, "r") as file:
        return file.read()

sort_param = readFile(sys.argv[2])
# formatting sort_param into a list of integers
sort_param = sort_param.replace("[", "").replace("]", "").split(",")
sort_param = [int(i) for i in sort_param]
test_count =  int(sys.argv[1])
lib_path = "target\\release\\rapl_lib.dll" if platform.system() == "Windows" else "target/release/librapl_lib.so"

# test method from Rosetta Code
def quickSort(arr):
    less = []
    pivotList = []
    more = []
    if len(arr) <= 1:
        return arr
    else:
        pivot = arr[0]
        for i in arr:
            if i < pivot:
                less.append(i)
            elif i > pivot:
                more.append(i)
            else:
                pivotList.append(i)
        less = quickSort(less)
        more = quickSort(more)
        return less + pivotList + more

# load lib
dll = cdll.LoadLibrary(lib_path)

# running benchmark
for i in range(test_count):
    # start recording
    dll.start_rapl()

    # run test
    result = quickSort(sort_param)

    # stop recording
    dll.stop_rapl()

    # stopping compiler optimizations
    if (len(result) < 42):
        print(result)
