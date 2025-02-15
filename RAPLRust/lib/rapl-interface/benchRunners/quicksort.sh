source ./benchRunners/count_input_params.sh
source ./benchRunners/bench_func.sh

testName="quicksort"
folder="quicksort"
count=1000
input="benchRunners/mergeSortParam" # getting input from file
inputLength=$(count_params `cat $input`)

echo "!!! Starting $testName !!!"
echo

#   Node
cmd="node ./benchmarks/$folder/javascript/bench.js $count"
runbenchmark "Node" $testName "$cmd" "$input" $inputLength

#   Python
cmd="python3 ./benchmarks/$folder/python/bench.py $count"
runbenchmark "Python" $testName "$cmd" "$input" $inputLength

#   Pypy
cmd="pypy ./benchmarks/$folder/python/bench.py $count"
runbenchmark "Pypy" $testName "$cmd" "$input" $inputLength

#   C#
cmd="dotnet run --project ./benchmarks/$folder/csharp/bench.csproj --configuration Release $count"
runbenchmark "Csharp" $testName "$cmd" "$input" $inputLength

#   Java
cmd="java --enable-native-access=ALL-UNNAMED --enable-preview --source 21 ./benchmarks/$folder/java/Bench.java $count"
runbenchmark "Java" $testName "$cmd" "$input" $inputLength

#   C
gcc benchmarks/$folder/c/bench.c -O3 -o benchmarks/$folder/c/bench -L./target/release -lrapl_lib -Wl,-rpath=./target/release
cmd="./benchmarks/$folder/c/bench $count"
runbenchmark "C" $testName "$cmd" "$input" $inputLength

#   C++
g++ benchmarks/$folder/cpp/bench.cpp -O3 -o benchmarks/$folder/cpp/bench -L./target/release -lrapl_lib -Wl,-rpath=./target/release 
cmd="./benchmarks/$folder/cpp/bench $count"
runbenchmark "Cpp" $testName "$cmd" "$input" $inputLength

echo "!!! Finished $testName !!!"
