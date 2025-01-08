#!/bin/bash
# Prints the assembly for a file and an overview of it to compare languages.
# Thus, when possible, LLVM-based compilers are used to minimize differences.
# Also, the highest optimization level and targeting native is used for all:
# - https://wiki.gentoo.org/wiki/GCC_optimization
# Finally, objdump is used if possible as outputting assembly can change it:
# - https://users.rust-lang.org/t/emit-asm-changes-the-produced-machine-code/17701
# - https://siliconsprawl.com/posts/rust-emit-asm/
# For OpenJDK -XX:+PrintAssembly or -XX:CompileCommand=print, is used:
# - https://blogs.oracle.com/javamagazine/post/java-hotspot-hsdis-disassembler
# - https://wiki.openjdk.org/display/HotSpot/PrintAssembly
# - https://docs.oracle.com/en/java/javase/21/docs/specs/man/java.html
# - https://github.com/openjdk/jdk/tree/master/src/utils/hsdis
# - https://chriswhocodes.com/hsdis/
# - https://github.com/AdoptOpenJDK/jitwatch
# For Microsoft .NET the DOTNET_JitDisasm environment variable is used:
# - https://github.com/dotnet/runtime/blob/main/docs/design/coreclr/jit/viewing-jit-dumps.md
# - https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-build
# - https://learn.microsoft.com/en-us/dotnet/core/deploying/
# - https://learn.microsoft.com/en-us/dotnet/core/deploying/deploy-with-cli
# - https://learn.microsoft.com/en-us/dotnet/core/deploying/native-aot/
# - https://github.com/EgorBo/Disasmo

## Helper Functions.
usage() {
  echo "usage: bash export-assembly.sh input-file [-f subroutine-name -i]"
  exit 1
}

usage_if_no_argument() {
  if [[ ! $1 -le $2 ]] then
    usage
  fi
}

inline_only_for_c_cpp_zig() {
  if [[ ! -z $1 ]]
  then
    echo "Inlining of source code is only supported for C, C++, and Zig".
    exit 1
  fi
}

objdump_argument() {
  if [[ -z $2 && -z $3 ]] then
    objdump "$1" --disassemble --demangle --no-addresses --no-show-raw-insn 
  elif [[ -z $2 ]] then
    objdump "$1" --disassemble --demangle --source --no-addresses --no-show-raw-insn
  elif [[ -z $3 ]] then
    objdump "$1" --disassemble --demangle --disassemble="$2" --no-addresses --no-show-raw-insn
  else
    objdump "$1" --disassemble --demangle --disassemble="$2" --source --no-addresses --no-show-raw-insn
  fi
}

count_instructions() {
  printf "\nBinary instructions summary:\n" >> "$1"
  awk '/^\t/{acc[$1]++} END { for(op in acc) { print acc[op],op } }' "$1" | sort -n -r >> "$1"
}

cat_and_clean() {
  rm "$1.bin"
  rm "$1.bin.o"
  cat "$1.s"
  rm "$1.s"
}

## Type Functions.
clang_c() {
  clang "$1" -g -O3 -march=native -o "$1.bin"
  objdump_argument "$1.bin" "$2" "$3" > "$1.s"
  count_instructions "$1.s"
  cat_and_clean "$1"
}

clang_cpp() {
  clang++ "$1" -g -O3 -march=native -o "$1.bin"
  objdump_argument "$1.bin" "$2" "$3" > "$1.s"
  count_instructions "$1.s"
  cat_and_clean "$1"
}

rustc_rs() {
  inline_only_for_c_cpp_zig $3

  rustc "$1" -g -C opt-level=3 -C target-cpu=native -o "$1.bin"
  objdump_argument "$1.bin" "$2" "$3" > "$1.s"
  count_instructions "$1.s"
  cat_and_clean "$1"
}

zig_zig() {
  zig build-exe "$1" -fno-strip -O ReleaseFast -mcpu native -femit-bin="$1.bin"
  objdump_argument "$1.bin" "$2" "$3" > "$1.s"
  count_instructions "$1.s"
  cat_and_clean "$1"
}

dotnet_scd_jit_cs() {
  inline_only_for_c_cpp_zig $3

  current_working_directory="$(pwd)"
  temporary_directory="$(mktemp -d)"
  execute_file="$(basename "$temporary_directory")"

  if [[ -z $2 ]] then
    jit_disasm="*"
  else
    jit_disasm="$2"
  fi

  pushd "$temporary_directory" > /dev/null
  dotnet new console > /dev/null
  cp "$current_working_directory/$1" "Program.cs"
  dotnet build -c Release > /dev/null
  DOTNET_JitDisasm="$jit_disasm" "./bin/Release/"*"/$execute_file"
  popd > /dev/null

  rm -rf "$temporary_directory"
}

openjdk_java() {
  inline_only_for_c_cpp_zig $3

  if [[ -f hsdis-amd64.so ]] then
    curl -s -O https://chriswhocodes.com/hsdis/hsdis-amd64.so
  fi

  javac "$1"

  class="$(grep class "$1" | cut -d' ' -f2)"

  if [[ -z "$2" ]] then
    LD_LIBRARY_PATH=. java -XX:+UnlockDiagnosticVMOptions -XX:+PrintAssembly "$class"
  else
    LD_LIBRARY_PATH=. java -XX:CompileCommand=print,"$2" "$class"
  fi

  rm "$class.class"
}

## Main.
if [[ $# -lt 1 || $# -gt 4 || ! -f "$1" ]] then
  usage
fi

suffix="${1##*.}"
subroutine_pattern=
inline_source_code=

argument_index=2
while [[ $argument_index -le $# ]]
do
  if [[ ${!argument_index} == "-f" ]] then
    let argument_index+=1
    usage_if_no_argument $argument_index $#
    subroutine_pattern="${!argument_index}"
  elif [[ ${!argument_index} == "-i" ]] then
    inline_source_code=true
  else
    usage
  fi
  let argument_index+=1
done

case $suffix in
  "c")
    clang_c "$1" "$subroutine_pattern" "$inline_source_code"
    ;;
  "cpp")
    clang_cpp "$1" "$subroutine_pattern" "$inline_source_code"
    ;;
  "rs")
    rustc_rs "$1" "$subroutine_pattern" "$inline_source_code"
    ;;
  "zig")
    zig_zig "$1" "$subroutine_pattern" "$inline_source_code"
    ;;
  "cs")
    dotnet_scd_jit_cs "$1" "$subroutine_pattern" "$inline_source_code"
    ;;
  "java")
    openjdk_java "$1" "$subroutine_pattern" "$inline_source_code"
    ;;
  *)
    echo "$input_file_suffix files are not support"
    exit 1
esac
