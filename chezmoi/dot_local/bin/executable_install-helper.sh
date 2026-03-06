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
        case "$default" in
            Y) printf '%s [Y/n] (5s): ' "$prompt" >&2 ;;
            N) printf '%s [y/N] (5s): ' "$prompt" >&2 ;;
            *) printf '%s [y/n]: '      "$prompt" >&2 ;;
        esac

        if [ -n "$default" ] && [ -t 0 ]; then
            read -t 5 -r input || {
                input="$default"
                printf '\nNo input! defaulting to: %s\n' "$input" >&2
            }
        else
            read -r input
        fi

        [ -z "$input" ] && [ -n "$default" ] && input="$default"

        case "$input" in
            [Yy]*) echo "Y"; return ;;
            [Nn]*) echo "N"; return ;;
            *)     print_error "Please answer with Y or N" ;;
        esac
    done
}

get_user_input() {
    if [ $# -lt 2 ]; then
        print_error "Usage: get_user_input <prompt> <option1> [option2 ...] [-d <default>]"
        return 1
    fi

    prompt="$1"
    shift

    default=""
    options=""
    delim=""

    while [ $# -gt 0 ]; do
        case "$1" in
            -d)
                [ -z "$2" ] && { print_error "-d requires a value"; return 1; }
                default="$2"
                shift 2
                ;;
            *)
                options="${options}${delim}${1}"
                delim="|"
                shift
                ;;
        esac
    done

    options="${options# }"

    if [ -z "$options" ]; then
        print_error "No options provided"
        return 1
    fi

    if [ -n "$default" ]; then
        case "|${options}|" in
            *"|${default}|"*) ;;
            *) print_error "Default '$default' is not in options: $(echo "$options" | tr '|' ' ')"; return 1 ;;
        esac
    fi

    # Build display string
    display=""
    delim=""
    IFS="|"
    for opt in $options; do
        if [ "$opt" = "$default" ]; then
            display="${display}${delim}[${opt}]"
        else
            display="${display}${delim}${opt}"
        fi
        delim=" "
    done
    unset IFS

    while :; do
        printf "%s (%s): " "$prompt" "$display" >&2
        read -r input

        [ -z "$input" ] && [ -n "$default" ] && input="$default"

        IFS="|"
        for opt in $options; do
            if [ "$input" = "$opt" ]; then
                unset IFS
                echo "$input"
                return 0
            fi
        done
        unset IFS

        print_error "Invalid option, choose from: $(echo "$options" | tr '|' ' ')"
    done
}

_SUDO_ACQUIRED=false

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
        _SUDO_ACQUIRED=true
    fi
}

drop_sudo() {
    if [ "$_SUDO_ACQUIRED" = true ] && command_exists sudo && ! is_root; then
        sudo -k
        _SUDO_ACQUIRED=false
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
    delim=""
    os=$(detect_os)

    case "$os" in
        darwin)
            command_exists brew && pax_manager="brew"
        ;;
        linux)
            for mgr in apt apk dnf yum pacman snap; do
                command_exists "$mgr" && pax_manager="${pax_manager}${delim}${mgr}" && delim="|"
            done
        ;;
        windows)
            for mgr in scoop choco winget; do
                command_exists "$mgr" && pax_manager="${pax_manager}${delim}${mgr}" && delim="|"
            done
        ;;
        *)
            command_exists nix && pax_manager="nix"
        ;;
    esac

    if [ -z "$pax_manager" ]; then
        print_error "Cannot detect package manager"
        return 1
    fi

    # Count without clobbering $@
    count=$(printf '%s' "$pax_manager" | tr -cd '|' | wc -c)
    count=$((count + 1))

    if [ "$count" -eq 1 ]; then
        echo "$pax_manager"
    else
        IFS="|"
        get_user_input "Detected multiple package managers" $pax_manager
        unset IFS
    fi
}

manager_requires_root() {
    case "$1" in
        apt|dnf|yum|pacman|apk|snap) return 0 ;;
        *) return 1 ;; # e.g. brew
    esac
}

update_pax_manager() {
    pax_manager=$(detect_pax_manager)

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

    case "$pax_manager" in
        apt|yum|apk|brew)
            CMD="update"
            ;;
        dnf|nix|scoop|choco|winget)
            CMD="upgrade"
            ;;
        pacman)
            CMD="-y"
            ;;
        snap)
            CMD="refresh"
            ;;
        *)
            print_error "Unknown package manager: $pax_manager"
            return 1
            ;;
    esac

    if [ -n "$SUDO" ]; then
        $SUDO $pax_manager $CMD || { print_error "Failed to update $pax_manager"; return 1; }
    else
        $pax_manager $CMD || { print_error "Failed to update $pax_manager"; return 1; }
    fi
}



install_package() {
    SUDO=""
    bypass_confirm=false
    pax_manager=
    packages=

    while [ $# -gt 0 ]; do
        case "$1" in
            -y) bypass_confirm=true ;;
            -p) pax_manager="$2"; shift ;;
            *) packages="$packages $1" ;;
        esac
        shift
    done

    packages="${packages# }"

    [ -z "$pax_manager" ] && pax_manager=$(detect_pax_manager)

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
    
    # update_pax_manager "$pax_manager"

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

        if [ -n "$SUDO" ]; then
            $SUDO $pax_manager $CMD || { print_error "Failed to install $pax"; return 1; }
        else
            $pax_manager $CMD || { print_error "Failed to install $pax"; return 1; }
        fi
    done
}


