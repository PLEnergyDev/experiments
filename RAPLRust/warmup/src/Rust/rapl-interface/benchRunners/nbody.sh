source ./benchRunners/bench_func.sh

testName="n-body"
folder="n-body"
count=1 #Testing only #TODO: change to actually useful number
body_count=50000000

echo "!!! Starting $testName !!!"
echo

#   C
gcc -fomit-frame-pointer -march=ivybridge benchmarks/$folder/c/bench.c -O3 -o benchmarks/$folder/c/bench -L./target/release -lrapl_lib -Wl,-rpath=./target/release 
cmd="./benchmarks/$folder/c/bench $count"
runbenchmark "C" $testName "$cmd" "$body_count"

#   C++
g++ -fomit-frame-pointer -march=ivybridge -std=c++17 benchmarks/$folder/cpp/bench.cpp -O3 -o benchmarks/$folder/cpp/bench -L./target/release -lrapl_lib -Wl,-rpath=./target/release
cmd="./benchmarks/$folder/cpp/bench $count"
runbenchmark "Cpp" $testName "$cmd" "$body_count"

#   Node
cmd="node ./benchmarks/$folder/javascript/bench.js $count"
runbenchmark "Node" $testName "$cmd" "$body_count"

#   Python
cmd="python3 ./benchmarks/$folder/python/bench.py $count"
runbenchmark "Python" $testName "$cmd" "$body_count"

#   Pypy
cmd="pypy ./benchmarks/$folder/python/bench.py $count"
runbenchmark "Pypy" $testName "$cmd" "$body_count"

#   C#
cmd="dotnet run --project ./benchmarks/$folder/csharp/Bench.csproj --configuration Release $count"
runbenchmark "Csharp" $testName "$cmd" "$body_count"

#   Java
cmd="java --enable-native-access=ALL-UNNAMED --enable-preview --source 21 ./benchmarks/$folder/java/Bench.java $count"
runbenchmark "Java" $testName "$cmd" "$body_count"

echo "!!! Finished $testName !!!"

