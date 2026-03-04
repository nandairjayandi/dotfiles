#!/bin/sh

### Message Helpers ###
print_info() {
    printf "%s%s\n" "[INFO]: " "$1"
}

print_error() {
    printf "%s%s\n" "[ERROR]: " "$1" >&2
}

### Essential Helper
command_exists() {
     type "$1" >/dev/null 2>&1;
}

### User Helper
get_bool() {
    prompt=$1
    default=$2
    input=
    
    while :; do
        if [ "$default" = "Y" ]; then
            printf "%s [Y/n]: " "$prompt" >&2
            read -r input
            [ -z "$input" ] && input="Y"
        elif [ "$default" = "N" ]; then
            printf "%s [y/N]: " "$prompt" >&2
            read -r input
            [ -z "$input" ] && input="N"
        else
            printf "%s [y/n]: " "$1" >&2
            read -r input
        fi
        case "$input" in
            [Yy]*)
                echo "Y" && return;;
            [Nn]*)
                echo "N" && return;;
            *)
                print_error "Please answer with Y or N";;
        esac
    done
}

# the current implementation is fragile but usable for this bootstrap
get_user_input() {
    prompt="$1"
    shift 1

    # since we shift $1 was previously $2
    # only allow it when there is a following arg i.e. $2 is implicit
    if [ "$1" = "-d" ]; then
        if [ -z "$3" ]; then
            print_error "-d requires options after default"
            return 1
        fi
        default="$2"
        shift 2
    else
        default="$1"
    fi

    # Check that we have options
    if [ $# -eq 0 ]; then
        print_error "No options provided"
        return 1
    fi

    options="$*"

    opt_exc_default=

    for opt in $options; do
        if [ "$opt" != "$default" ]; then
            opt_exc_default="$opt_exc_default $opt"
        fi
    done

    opt_exc_default="${opt_exc_default# }"

    while :; do
        printf "%s [%s] %s: " "$prompt" "$default" "$opt_exc_default"
        read -r input
        [ -z "$input" ] && input="$default"

        for opt in $options; do
            if [ "$input" = "$opt" ]; then 
                echo "$input"
                return 0
            fi
        done

        print_error "Invalid option choose from $options" 
    done
}


is_root() {
    [ "$(id -u)" -eq 0 ]
}

request_sudo() {
    if command_exists sudo && ! is_root; then
    print_info "Requesting sudo..."
        sudo -v || {
            print_error "Cannot obtain sudo privilege"
            return 1
        }
    fi
}

drop_sudo() {
    if command_exists sudo && is_root; then
        sudo -k
        print_info "sudo privilege revoked"
    fi
}

### System Manager
detect_os() {
    if [ -z "$OSTYPE" ]; then
        if command_exists uname; then
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
    pax_manager=""
    os=$(detect_os)

    case "$os" in
        darwin)
            command_exists brew && pax_manager="$pax_manager brew"
        ;;
        linux)
            command_exists apt && pax_manager="$pax_manager apt"
            command_exists apk && pax_manager="$pax_manager apk"
            command_exists dnf && pax_manager="$pax_manager dnf"
            command_exists yum && pax_manager="$pax_manager yum"
            command_exists pacman && pax_manager="$pax_manager pacman"
            command_exists snap && pax_manager="$pax_manager snap"
        ;;
        windows)
            command_exists scoop && pax_manager="$pax_manager scoop"
            command_exists choco && pax_manager="$pax_manager choco"
            command_exists winget && pax_manager="$pax_manager winget"
        ;;
        *) 
            command_exists nix && pax_manager="$pax_manager nix"
        ;;
    esac

    # if pax_manager ... # when there are more than few, prompt user for manual input
    pax_manager="${pax_manager# }"

    set -- $pax_manager
    count=$#

    if [ "$count" -eq 0 ]; then
        print_error "Cannot detect package manager"
    elif [ "$count" -eq 1 ]; then
        echo $pax_manager
    else
        get_user_input "Detected multiple package manager" "$pax_manager"
    fi

}

install_package() {
    # Always initialize
    SUDO=""
    bypass_confirm=false
    pax_manager=
    packages=

    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            -y) bypass_confirm=true ;;
            -p) pax_manager="$2"; shift ;;
            *) packages="$packages $1" ;;
        esac
        shift
    done

    packages="${packages# }"

    # Detect package manager if not provided
    [ -z "$pax_manager" ] && pax_manager=$(detect_pax_manager)

    # Determine if we need sudo
    manager_requires_root() {
        case "$1" in
            apt|dnf|yum|pacman|apk|snap) return 0 ;;
            *) return 1 ;; # e.g. brew
        esac
    }

    if manager_requires_root "$pax_manager"; then
        if is_root; then
            SUDO=""
        elif command_exists sudo; then
            request_sudo || return 1
            SUDO="sudo"
        else
            print_error "$pax_manager requires root. Run as root."
            return 1
        fi
    fi

    # Install packages
    for pax in $packages; do
        print_info "Installing '$pax' with '$pax_manager'"

        case "$pax_manager" in
            apt)
                [ "$bypass_confirm" = true ] && CMD="install -y $pax" || CMD="install $pax"
                ;;
            dnf)
                [ "$bypass_confirm" = true ] && CMD="install -y $pax" || CMD="install $pax"
                ;;
            yum)
                [ "$bypass_confirm" = true ] && CMD="install -y $pax" || CMD="install $pax"
                ;;
            pacman)
                [ "$bypass_confirm" = true ] && CMD="-S --noconfirm $pax" || CMD="-S $pax"
                ;;
            apk)
                CMD="add $pax"
                ;;
            snap)
                [ "$bypass_confirm" = true ] && CMD="install $pax --yes" || CMD="install $pax"
                ;;
            brew|nix|scoop|choco|winget)
                CMD="install $pax"
                ;;
            *)
                print_error "Unknown package manager: $pax_manager"
                return 1
                ;;
        esac

        # Execute command with or without sudo
        if [ -n "$SUDO" ]; then
            $SUDO $pax_manager $CMD || { print_error "Failed to install $pax"; return 1; }
        else
            $pax_manager $CMD || { print_error "Failed to install $pax"; return 1; }
        fi
    done
}

#### Start Bootstrap ####

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OS=$(detect_os)
PAX_MANAGER=$(detect_pax_manager)

export OS PAX_MANAGER

print_info "OS=$OS"
print_info "PAX_MANAGER=$PAX_MANAGER"
print_info "$SCRIPT_DIR"

# Default XDG paths
export XDG_DATA_HOME="$HOME"/.local/share
export XDG_CONFIG_HOME="$HOME"/.config
export XDG_STATE_HOME="$HOME"/.local/state
export XDG_CACHE_HOME="$HOME"/.cache

install_package -y git curl zsh

if [ "$(get_bool "Handoff to Chezmoi?" "Y")" = "Y" ]; then
    install_package -y chezmoi 
    zsh -c "chezmoi init --source $SCRIPT_DIR/chezmoi --apply"
else 
    exit 0
fi