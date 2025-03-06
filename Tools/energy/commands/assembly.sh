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
# For .NET the DOTNET_JitDisasm and DOTNET_JitDisasmDiffable environment variables are used:
# - https://github.com/dotnet/runtime/blob/main/docs/design/coreclr/jit/viewing-jit-dumps.md
# - https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-build
# - https://learn.microsoft.com/en-us/dotnet/core/deploying/
# - https://learn.microsoft.com/en-us/dotnet/core/deploying/deploy-with-cli
# - https://learn.microsoft.com/en-us/dotnet/core/deploying/native-aot/
# - https://github.com/EgorBo/Disasmo

assembly_description() {
    echo "Prints the assembly for a file and an overview of it to compare languages"
}

assembly_help() {
    cat << HELP
Usage:
    $TOOL_NAME assembly input-file [OPTIONS]

Options:
    -f SUBROUTINE PATTERN
    -o OBJDUMP COMMAND
    -- COMMAND-LINE ARGUMENTS
    -h, --help             Show this help message

SUBROUTINE PATTERN:
    .c      see --disassemble=symbol in man objdump
    .cpp    see --disassemble=symbol in man objdump
    .rust   see --disassemble=symbol in man objdump
    .zig    see --disassemble=symbol in man objdump
    ELF     see --disassemble=symbol in man objdump
    .cs     see https://github.com/dotnet/runtime/blob/main/docs/design/coreclr/jit/viewing-jit-dumps.md#specifying-method-names
    .dll    see https://github.com/dotnet/runtime/blob/main/docs/design/coreclr/jit/viewing-jit-dumps.md#specifying-method-names
    .java   see -XX:CompileCommand=command,method[,option] in https://docs.oracle.com/en/java/javase/23/docs/specs/man/java.html
    .class  see -XX:CompileCommand=command,method[,option] in https://docs.oracle.com/en/java/javase/23/docs/specs/man/java.html

OBJDUMP COMMAND:
    stats   show a summary of the assembly instructions used
    source  inline source code and assembly for C, C++, and Zig
    jumps   visualize jumps by drawing lines between addresses

HELP
}

count_instructions() {
  printf "\nBinary instructions summary:\n" >> "$1"
  awk '/^\t/{acc[$1]++} END { for(op in acc) { print acc[op],op } }' "$1" | sort -n -r >> "$1"
}

objdump_with_command() {
  objdump_shell_command="objdump $1 --disassemble --demangle --no-addresses --no-show-raw-insn  --disassembler-color=extended-color"

  if [[ ! -z "$2" ]]; then
    objdump_shell_command="$objdump_shell_command --disassemble=$2"
  fi

  if [[ "$3" == "stats" ]]; then
    objdump_shell_command="$objdump_shell_command > $1.s"
    eval "$objdump_shell_command"
    count_instructions "$1.s"
  elif [[ "$3" == "source" ]]; then
    objdump_shell_command="$objdump_shell_command --source  > $1.s"
    eval "$objdump_shell_command"
  elif [[ "$3" == "jumps" ]]; then
    objdump_shell_command="$objdump_shell_command --visualize-jumps=extended-color  > $1.s"
    eval "$objdump_shell_command"
  elif [[ ! -z $3 ]]; then
    error "$3 is not a supported objdump command"
  else
    objdump_shell_command="$objdump_shell_command > $1.s"
    eval "$objdump_shell_command"
  fi
}

error_if_objdump() {
  if [[ ! -z $1 ]]; then
    error "objdump commands are not supported by C# and Java"
  fi
}

cat_and_clean() {
  rm -f "$1.bin"
  rm -f "$1.bin.o"
  cat "$1.s"
  rm -f "$1.s"
}

## Type Functions.
clang_c() {
  clang "$1" -g -O3 -march=native -o "$1.bin"
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

  pushd "$temporary_directory" > /dev/null
  dotnet new console > /dev/null
  cp "$current_working_directory/$1" "Program.cs"
  dotnet build -c Release > /dev/null
  dotnet_scd_jit_dll "bin/Release/"*"/$execute_file.dll" "$2" "$3" "${@:4}"
  popd > /dev/null

  rm -rf "$temporary_directory"
}

dotnet_scd_jit_dll() {
  error_if_objdump "$3"

  if [[ -z $2 ]]; then
    jit_disasm="*"
  else
    jit_disasm="$2"
  fi

  DOTNET_JitDisasm="$jit_disasm" DOTNET_JitDisasmDiffable=1 "dotnet" "$1" "${@:4}"
}

openjdk_java() {
  error_if_objdump "$3"
  javac "$1"
  class_file="$(grep class "$1" | cut -d' ' -f2).class"
  openjdk_class "$class_file" "$2" "$3" "${@:4}"
  rm "$class.class"
}

openjdk_class() {
  error_if_objdump "$3"

  if [[ ! -f hsdis-amd64.so ]]; then
    curl -s -O https://chriswhocodes.com/hsdis/hsdis-amd64.so
  fi

  class=${1%.class}

  if [[ -z "$2" ]]; then
    LD_LIBRARY_PATH=. java -XX:+UnlockDiagnosticVMOptions -XX:+PrintAssembly "$class" "${@:4}"
  else
    LD_LIBRARY_PATH=. java -XX:CompileCommand=print,"$2" "$class" "${@:4}"
  fi
}

assembly_main() {
    local options=""
    local subroutine_pattern=""
    local objdump_command=""
    local input_file=""
    local input_file_suffix=""
    local extra_args=()

    options=$(getopt -o f:o: -- "$@")
    eval set -- "$options"

    while true; do
        case "$1" in
            -f)
                subroutine_pattern="$2"
                shift
                ;;
            -o)
                objdump_command="$2"
                shift
                ;;
            --)
                shift
                input_file="$1"
                shift
                extra_args=("$@")
                break
                ;;
            *)
                error "'$1' is not a known option. See '$TOOL_NAME assembly --help'."
                ;;
        esac
        shift
    done

    if [[ -z "$input_file" ]]; then
        assembly_help
        exit 1
    fi

    if [[ ! -f "$input_file" ]]; then
        error "File \"$input_file\" does not exist."
    fi

    input_file_suffix="${input_file##*.}"
    case $input_file_suffix in
      "c")
        clang_c "$input_file" "$subroutine_pattern" "$objdump_command"
        ;;
      "cpp")
        clang_cpp "$input_file" "$subroutine_pattern" "$objdump_command"
        ;;
      "rs")
        rustc_rs "$input_file" "$subroutine_pattern" "$objdump_command"
        ;;
      "zig")
        zig_zig "$input_file" "$subroutine_pattern" "$objdump_command"
        ;;
      "cs")
        dotnet_scd_jit_cs "$input_file" "$subroutine_pattern" "$objdump_command" "$extra_args"
        ;;
      "dll")
        dotnet_scd_jit_dll "$input_file" "$subroutine_pattern" "$objdump_command" "$extra_args"
        ;;
      "java")
        openjdk_java "$input_file" "$subroutine_pattern" "$objdump_command" "$extra_args"
        ;;
      "class")
        openjdk_class "$input_file" "$subroutine_pattern" "$objdump_command" "$extra_args"
        ;;
      *)
        if file "$input_file" | grep -q ": ELF"; then
          elf "$input_file" "$subroutine_pattern" "$objdump_command" "$@"
        else
          error "\"$input_file\" is not an ELF file or supported source code"
        fi
    esac
}
