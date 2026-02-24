#!/bin/sh

set -e

if command -v apk >/dev/null 2>&1; then
	PAX_MANAGER="apk"
elif command -v apt >/dev/null 2>&1; then
	PAX_MANAGER="apt"
	apt update
elif command -v dnf >/dev/null 2>&1; then
	PAX_MANAGER="dnf"
elif command -v zypper >/dev/null 2>&1; then
	PAX_MANAGER="zypper"
elif command -v brew >/dev/null 2>&1; then
	PAX_MANAGER="brew"
elif command -v yum >/dev/null 2>&1; then
	PAX_MANAGER="yum"
elif command -v pacman >/dev/null 2>&1; then
	PAX_MANAGER="pacman"
else
	echo "[ERROR] Cannot identify eligible package manager. Exiting..."
	exit 1
fi

install_packages() {
	for pkg in "$@"; do
		echo "Installing $pkg"
		# print_info "Installing $pkg"

		case $PAX_MANAGER in
			apk) apk add --no-cache "$pkg" ;;
			apt) apt install -y "$pkg" ;; 
		esac
	done

}

echo "Checking if Zsh exists..."
if ! command -v zsh >/dev/null 2>&1; then
	echo "Zsh not found. Installing with $PAX_MANAGER"
	install_packages zsh
fi

if [ -z "$ZSH_VERSION" ]; then
	exec zsh "$0" "$@"
fi

### start: helper function ###
print_error() {
	print -P "%b%f{red}[error] %b%f$1"
}
print_info() {
	print -P "%b%f{yellow}[info] %b%f$1"
}
print_bool() {
    local prompt="$1"
    local reply

    while true; do
        print -nP "%F{cyan}[?]%f $prompt %F{magenta}(y/n)%f: "
        read -k 1 reply
        print

        case "$reply" in
            [Yy]) return 0 ;;
            [Nn]) return 1 ;;
        esac

        print -P "%F{red}[error]%f Please press y or n."
    done
}
### END: Helper Function ###

print_info "Zsh version $ZSH_VERSION is installed. Starting bootstrap..."

setopt extended_glob err_exit
zmodload -m -F zsh/files b:zf_\*

SCRIPT_DIR=${0:A:h}

if [[ $SCRIPT_DIR == $HOME.homedir* ]]; then
    SCRIPT_DIR=${SCRIPT_DIR/.homedir/}
fi
cd $SCRIPT_DIR

XDG_CACHE_HOME=$HOME/.cache
XDG_CONFIG_HOME=$HOME/.config
XDG_DATA_HOME=$HOME/.local/share
XDG_STATE_HOME=$HOME/.local/state

print_info "Creating directory tree"
zf_mkdir -p $XDG_CONFIG_HOME/{git/local,htop,gnupg,nvim/{plugin}}

zf_mkdir -p $XDG_CACHE_HOME/{zsh}

zf_mkdir -p $XDG_DATA_HOME/{{goenv,jenv,luaenv,nodenv,phpenv,plenv,pyenv,rbenv}/plugins,zsh,nvim/site/pack/plugins}

zf_mkdir -p $XDG_STATE_HOME

zf_mkdir -p $HOME/.local/{bin,etc}

zf_chmod 700 $XDG_CONFIG_HOME/gnupg
print "  ...done"

if print_bool "install curl,git"; then
	install_packages curl git
fi

if print_bool "install docker"; then
	install_packages docker
fi