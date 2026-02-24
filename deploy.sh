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

echo "Zsh version $ZSH_VERSION is installed. Starting bootstrap..."

XDG_CACHE_HOME=$HOME/.cache
XDG_CONFIG_HOME=$HOME/.config
XDG_DATA_HOME=$HOME/.local/share
XDG_STATE_HOME=$HOME/.local/state
