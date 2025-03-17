#!/bin/bash

LIB_DIR="{{LIB_DIR}}"
NAME="{{NAME}}"
COMMANDS_DIR="{{COMMANDS_DIR}}"
SCRIPTS_DIR="{{SCRIPTS_DIR}}"
SETUPS_DIR="{{SETUPS_DIR}}"

error() {
    echo -e "Error: $1" >&2
    exit 1
}

warning() {
    echo -e "Warning: $1"
}

info() {
    echo -e "\nInfo: $1"
}

energy_help() {
    cat << HELP
Usage:
    $NAME [--version|--help] COMMAND [OPTIONS]

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

get_available_commands() {
    local commands=()
    for command_sh in "$COMMANDS_DIR"/*.sh; do
        if [[ -f "$command_sh" ]]; then
            commands+=("$(basename "$command_sh" .sh)")
        fi
    done
    echo "${commands[@]}"
}

source_available_commands() {
    local commands=()
    for command_sh in "$COMMANDS_DIR"/*.sh; do
        if [[ -f "$command_sh" ]]; then
            commands+=("$(basename "$command_sh" .sh)")
            source "$command_sh"
        fi
    done
}

main() {
    local command=""
    local show_help=false
    local args=()
    local available_commands=$(get_available_commands)

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
