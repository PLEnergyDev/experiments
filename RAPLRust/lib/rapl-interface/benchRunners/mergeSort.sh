source ./benchRunners/count_input_params.sh
source ./benchRunners/bench_func.sh

testName="mergeSort"
folder="mergesort"
count=1000
mergeInput="benchRunners/mergeSortParam" # getting input from file
inputLength=$(count_params `cat $mergeInput`)

echo "!!! Starting $testName !!!"
echo

#   Node
cmd="node ./benchmarks/$folder/javascript/bench.js $count"
runbenchmark "Node" $testName "$cmd" "$mergeInput" $inputLength

#   Python
cmd="python3 ./benchmarks/$folder/python/bench.py $count"
runbenchmark "Python" $testName "$cmd" "$mergeInput" $inputLength

#   Pypy
cmd="pypy ./benchmarks/$folder/python/bench.py $count"
runbenchmark "Pypy" $testName "$cmd" "$mergeInput" $inputLength

#   C#
cmd="dotnet run --project ./benchmarks/$folder/csharp/Bench.csproj --configuration Release $count" 
runbenchmark "Csharp" $testName "$cmd" "$mergeInput" $inputLength

#   Java
cmd="java --enable-native-access=ALL-UNNAMED --enable-preview --source 21 ./benchmarks/$folder/java/Bench.java $count"
runbenchmark "Java" $testName "$cmd" "$mergeInput" $inputLength

#   C
gcc benchmarks/$folder/c/bench.c -O3 -o benchmarks/$folder/c/bench -L./target/release -lrapl_lib -Wl,-rpath=./target/release #Compile first
cmd="./benchmarks/$folder/c/bench $count"
runbenchmark "C" $testName "$cmd" "$mergeInput" $inputLength

#   C++
g++ benchmarks/$folder/cpp/bench.cpp -O3 -o benchmarks/$folder/cpp/bench -L./target/release -lrapl_lib -Wl,-rpath=./target/release #Compile first
cmd="./benchmarks/$folder/cpp/bench $count"
runbenchmark "Cpp" $testName "$cmd" "$mergeInput" $inputLength

echo "!!! Finished $testName !!!"
