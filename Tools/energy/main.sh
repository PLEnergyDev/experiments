#!/bin/bash

LIB_DIR="{{LIB_DIR}}"
NAME="{{NAME}}"
COMMANDS_DIR="{{COMMANDS_DIR}}"
SCRIPTS_DIR="{{SCRIPTS_DIR}}"
SETUPS_DIR="{{SETUPS_DIR}}"

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
NC=$(tput sgr0)

error() {
    echo -e "${RED}Error:${NC} $1" >&2
    exit 1
}

warning() {
    echo -e "${YELLOW}Warning:${NC} $1"
}

info() {
    echo -e "\n${BLUE}Info:${NC} $1"
}

energy_help() {
    cat << HELP
Usage:
    $NAME [--help] COMMAND [OPTIONS]

Commands:
HELP

    for command_sh in "$COMMANDS_DIR"/*.sh; do
        if [[ -f "$command_sh" ]]; then
            description="No description available"
            command_name=$(basename "$command_sh" .sh)
            if [[ -n "$(command -v "${command_name}_description")" ]]; then
                description=$("${command_name}_description")
            fi
            printf "    %-10s %s\n" "$command_name" "$description"
        fi
    done

    echo
}

source_available_commands() {
    for command_sh in "$COMMANDS_DIR"/*.sh; do
        if [[ -f "$command_sh" ]]; then
            source "$command_sh"
        fi
    done
}

main() {
    local command=""
    local show_help=false
    local args=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help=true
                break
                ;;
            *)
                if [[ -z "$command" ]]; then
                    command="$1"
                else
                    args+=("$1")
                fi
                ;;
        esac
        shift
    done

    source_available_commands

    if [[ -z $command ]]; then
        energy_help
        exit 1
    fi

    if [[ ! -f "$COMMANDS_DIR/${command}.sh" ]]; then
        error "Unkown command '$command'"
    fi

    if $show_help; then
        "${command}_help"
        exit 0
    fi

    "${command}_main" "${args[@]}"
}

main "$@"
