source ./benchRunners/bench_func.sh

testName="sleep"
folder="sleep"
count=1
sleep_time=5

echo "!!! Starting $testName !!!"
echo

#   C
gcc benchmarks/$folder/c/bench.c -O3 -o benchmarks/$folder/c/bench -L./target/release -lrapl_lib -Wl,-rpath=./target/release
cmd="./benchmarks/$folder/c/bench $count" 
runbenchmark "C" $testName "$cmd" $sleep_time

#   C++
g++ benchmarks/$folder/cpp/bench.cpp -O3 -o benchmarks/$folder/cpp/bench -L./target/release -lrapl_lib -Wl,-rpath=./target/release
cmd="./benchmarks/$folder/cpp/bench $count"
runbenchmark "Cpp" $testName "$cmd" $sleep_time

#   Node
cmd="node ./benchmarks/$folder/javascript/bench.js $count"
runbenchmark "Node" $testName "$cmd" $sleep_time

#   Python
cmd="python3 ./benchmarks/$folder/python/bench.py $count"
runbenchmark "Python" $testName "$cmd" $sleep_time

#   Pypy
cmd="pypy ./benchmarks/$folder/python/bench.py $count"
runbenchmark "Pypy" $testName "$cmd" $sleep_time

#   C#
cmd="dotnet run --project ./benchmarks/$folder/csharp/Bench.csproj --configuration Release $count"
runbenchmark "Csharp" $testName "$cmd" $sleep_time

#   Java
cmd="java --enable-native-access=ALL-UNNAMED --enable-preview --source 21 ./benchmarks/$folder/java/Bench.java $count"
runbenchmark "Java" $testName "$cmd" $sleep_time

echo "!!! Finished $testName !!!"
