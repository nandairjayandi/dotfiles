#!/bin/sh

### Message Helpers ###
BOLD="\033[1m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

print_message() {
    local style=$1
    local message=$2
    printf "${message}"
}

print_info() {
    print_message 
    echo ": $1"
}

print_error() {
    print_message "${BOLD}${RED}" "[ERROR]"
    echo ": $1"
}

### Essential Helper
command_exists() {
     command -v "$1" >/dev/null 2>&1;
}

### User Helper
get_bool() {
    local prompt=$1
    local default=$2
    local input
    
    while true; do
        if [ "default" = "Y"]; then
            read -p 
        fi
    done
}


### System Manager
detect_os() {
    if [ -z "$OSTYPE" ]; then
        if command_exist uname; then
            case "$(uname -s)" in
                Linux*) echo "linux";;
                Darwin*) echo "darwin";;
                CYGWIN*|MSYS*|MINGW*) echo "windows";;
                *)  echo "unknown";;
            esac
        else
            if [ -n "$SYSTEMROOT" ] && [ -d "$SYSTEMROOT" ]; then
                echo "windows"
            else
                echo "unknown"
            fi
            
        fi
    else 
        case "$OSTYPE" in
            linux*) echo "linux";;
            darwin*) echo "darwin";;
            mingw*|msys*|cygwin*) echo "windows";;
            *) echo "unknown";;
        esac
    fi
}

detect_pax_manager() {
    local pax_manager=""

    command_exists apt && pax_manager="pax_manager apt"
    command_exists apk && pax_manager="pax_manager apk"
    command_exists dnf && pax_manager="pax_manager dnf"
    command_exists yum && pax_manager="pax_manager yum"
    command_exists pacman && pax_manager="pax_manager pacman"
    command_exists snap && pax_manager="pax_manager snap"
    command_exists nix && pax_manager="pax_manager nix"

    if pax_manager ... # when there are more than few, prompt user for manual input
}




install_package () {
    local bypass_confirm=false
    local packages=""

    for arg in "$@"; do
        if [ "arg" = "-y" ]; then
            bypass_confirm=true
        else
            packages="$packages $arg"
        fi
    done


}