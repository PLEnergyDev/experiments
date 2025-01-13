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

## Configuration.
set -e

## Helper Functions.
usage() {
  echo "usage: bash export-assembly.sh input-file [-foh]"
  exit 1
}

help() {
cat << HELP
usage: bash export-assembly.sh input-file [optional-arguments]

OPTIONAL ARGUMENTS:
-f subroutine-pattern
-o objdump-command
-h

SUBROUTINE PATTERN:
.c      see --disassemble=symbol in man objdump
.cpp    see --disassemble=symbol in man objdump
.rust   see --disassemble=symbol in man objdump
.zig    see --disassemble=symbol in man objdump
ELF     see --disassemble=symbol in man objdump
.cs     see https://github.com/dotnet/runtime/blob/main/docs/design/coreclr/jit/viewing-jit-dumps.md#specifying-method-names
.java   see -XX:CompileCommand=command,method[,option] in https://docs.oracle.com/en/java/javase/23/docs/specs/man/java.html

OBJDUMP COMMAND:
stats   show a summary of the assembly instructions used
source  inline source code and assembly for C, C++, and Zig
jumps   visualize jumps by drawing lines between addresses
HELP
  exit 1
}

error() {
  echo "ERROR: $1" 1>&2
  exit 1
}

error_if_no_argument() {
  if [[ ! $1 -le $2 ]] then
    error "missing argument for the flag $3"
  fi
}

error_if_objdump() {
  if [[ ! -z $1 ]] then
    error "objdump commands are not supported by C# and Java"
  fi
}

count_instructions() {
  printf "\nBinary instructions summary:\n" >> "$1"
  awk '/^\t/{acc[$1]++} END { for(op in acc) { print acc[op],op } }' "$1" | sort -n -r >> "$1"
}

objdump_with_command() {
  objdump_shell_command="objdump $1 --disassemble --demangle --no-addresses --no-show-raw-insn  --disassembler-color=extended-color"

  if [[ ! -z "$2" ]] then
    objdump_shell_command="$objdump_shell_command --disassemble=$2"
  fi

  if [[ "$3" == "stats" ]] then
    objdump_shell_command="$objdump_shell_command > $1.s"
    eval "$objdump_shell_command"
    count_instructions "$1.s"
  elif [[ "$3" == "source" ]] then
    objdump_shell_command="$objdump_shell_command --source  > $1.s"
    eval "$objdump_shell_command"
  elif [[ "$3" == "jumps" ]] then
    objdump_shell_command="$objdump_shell_command --visualize-jumps=extended-color  > $1.s"
    eval "$objdump_shell_command"
  elif [[ ! -z $3 ]] then
    error "$3 is not a supported objdump command"
  else
    objdump_shell_command="$objdump_shell_command > $1.s"
    eval "$objdump_shell_command"
  fi
}

cat_and_clean() {
  rm -f "$1.bin"
  rm -f "$1.bin.o"
  cat "$1.bin.s"
  rm -f "$1.bin.s"
}

## Type Functions.
clang_c() {
  gcc "$1" -g -O3 -march=native -o "$1.bin"
  objdump_with_command "$1.bin" "$2" "$3"
  cat_and_clean "$1"
}

clang_cpp() {
  clang++ "$1" -g -O3 -march=native -o "$1.bin"
  objdump_with_command "$1.bin" "$2" "$3"
  cat_and_clean "$1"
}

rustc_rs() {
  rustc "$1" -g -C opt-level=3 -C target-cpu=native -o "$1.bin"
  objdump_with_command "$1.bin" "$2" "$3"
  cat_and_clean "$1"
}

zig_zig() {
  zig build-exe "$1" -fno-strip -O ReleaseFast -mcpu native -femit-bin="$1.bin"
  objdump_with_command "$1.bin" "$2" "$3"
  cat_and_clean "$1"
}

elf() {
  objdump_with_command "$1" "$2" "$3"
  cat_and_clean "$1"
}

dotnet_scd_jit_cs() {
  error_if_objdump "$3"

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
  error_if_objdump "$3"

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
if [[ $# -lt 1 ]] then
  usage
fi

if [[ "$1" == "-h" ]] then
  help
fi

if [[ ! -f "$1" ]] then
  error "the file \"$1\" does not exist."
fi

suffix="${1##*.}"
subroutine_pattern=
objdump_command=

argument_index=2
while [[ $argument_index -le $# ]]
do
  if [[ ${!argument_index} == "-f" ]] then
    let argument_index+=1
    error_if_no_argument $argument_index $# "-f"
    subroutine_pattern="${!argument_index}"
  elif [[ ${!argument_index} == "-o" ]] then
    let argument_index+=1
    error_if_no_argument $argument_index $# "-o"
    objdump_command="${!argument_index}"
  elif [[ ${!argument_index} == "-h" ]] then
    help
  else
    usage
  fi
  let argument_index+=1
done

case $suffix in
  "c")
    clang_c "$1" "$subroutine_pattern" "$objdump_command"
    ;;
  "cpp")
    clang_cpp "$1" "$subroutine_pattern" "$objdump_command"
    ;;
  "rs")
    rustc_rs "$1" "$subroutine_pattern" "$objdump_command"
    ;;
  "zig")
    zig_zig "$1" "$subroutine_pattern" "$objdump_command"
    ;;
  "cs")
    dotnet_scd_jit_cs "$1" "$subroutine_pattern" "$objdump_command"
    ;;
  "java")
    openjdk_java "$1" "$subroutine_pattern" "$objdump_command"
    ;;
  *)
    if file "$1" | grep -q ": ELF"; then
      elf "$1" "$subroutine_pattern" "$objdump_command"
    else
      error "\"$1\" is not an ELF file or supported source code"
    fi
esac
