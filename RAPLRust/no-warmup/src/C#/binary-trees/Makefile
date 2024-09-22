compile:
	cp binarytrees.csharpcore-4.csharpcore Program.cs
	dotnet build -c Release

measure:
	sudo modprobe msr
	sudo ../../RAPL/target/release/RAPL "dotnet ./bin/Release/net8.0/tmp.dll 21"

run:
	dotnet ./bin/Release/net8.0/tmp.dll 21

mem:
	time -v dotnet ./bin/Release/net8.0/tmp.dll 21

valgrind:
	valgrind --tool=massif --stacks=yes dotnet ./bin/Release/net8.0/tmp.dll 21
