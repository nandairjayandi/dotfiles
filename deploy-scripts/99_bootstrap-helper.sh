#!/bin/sh

### Message Helpers ###
# print_message() {
#     local style=$1
#     local message=$2
#     printf "%s%s"
# }

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
            printf "%s [Y/n]: " "$prompt"
            read -r input
            [ -z "$input" ] && input="Y"
        elif [ "$default" = "N" ]; then
            printf "%s [y/N]: " "$prompt"
            read -r input
            [ -z "$input" ] && input="N"
        else
            printf "%s [y/n]: " "$1"
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

# get_user_input() {
#     prompt=$1
#     default=$2
#     shift 2 # remove the first two arguments, the leftover argument will be used below
#     options="$*" # the remaining argument

#     # conditional if default is not provided extract from 
#     []

#     input=

#     while :; do
#         if [ -n "$default" ]; then
#             printf "[%s]" "$prompt" "$default" 
#         else

        
#     done
# }

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
        default="${options%% *}"
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

    count=$(printf "%s" "$pax_manager" | wc -w | tr -d ' ')

    if [ "$count" -eq 0 ]; then
        print_error "Cannot detect package manager"
    elif [ "$count" -eq 1 ]; then
        echo $pax_manager
    else
        get_user_input "Detected multiple package manager" "$pax_manager"
    fi

}

install_package () {
    bypass_confirm=false
    # curl_link=
    packages=

    for arg in "$@"; do
        if [ "$arg" = "-y" ]; then
            bypass_confirm=true
        # elif [ "$arg" = "-c" ]; then
        #     shift
        #     curl_link="$1"
        else
            packages="$packages $arg"
        fi
    done

    packages="${packages# }"
    pax_manager=detect_pax_manager

    for pax in $packages; do
        print_info "Installing '$pax' with '$pax_manager'"
  
        case "$pax_manager" in
            apt)
                if [ "$bypass_confirm" = true ]; then
                    sudo apt install -y "$pax"
                else
                    sudo apt install "$pax"
                fi
                ;;
            apk) sudo apk add "$pax" ;;
            dnf)
                if [ "$bypass_confirm" = true ]; then
                    sudo dnf install -y "$pax"
                else
                    sudo dnf install "$pax"
                fi
                ;;
            yum)
                if [ "$bypass_confirm" = true ]; then
                    sudo yum install -y "$pax"
                else
                    sudo yum install "$pax"
                fi
                ;;
            pacman)
                if [ "$bypass_confirm" = true ]; then
                    sudo pacman -S --noconfirm "$pax"
                else
                    sudo pacman -S "$pax"
                fi
                ;;
            brew)brew install "$pax";;
            snap)
                if [ "$bypass_confirm" = true ]; then
                    sudo snap install "$pax" --yes
                else
                    sudo snap install "$pax"
                fi
                ;;
        esac
        
        if [ $? -ne 0 ]; then
            print_error "Failed to install $pax"
            return 1
        fi
    done

    # Don't curl without consent dumbass
    # if [ -n "$curl_link" ]; then
    #     print_info "Downloading from $curl_link"
    #     if command_exists curl; then
    #         curl -O "$curl_link"
    #     elif command_exists wget; then
    #         wget "$curl_link"
    #     else
    #         print_error "Neither curl nor wget is available"
    #         return 1
    #     fi
    # fi
}