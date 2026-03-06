#!/bin/sh

#### Start Bootstrap ####

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)" && . "$SCRIPT_DIR"/chezmoi/dot_local/bin/executable_install-helper.sh
OS=$(detect_os)
PAX_MANAGER=$(detect_pax_manager)

export OS PAX_MANAGER

print_info "OS=$OS"
print_info "PAX_MANAGER=$PAX_MANAGER"
print_info "$SCRIPT_DIR"

update_pax_manager
install_package  -y curl git zsh

git clone --depth=1 https://github.com/mattmc3/antidote.git ${ZDOTDIR:-$HOME}/.antidote

if [ "$(get_bool "Handoff to Chezmoi?" "Y")" = "Y" ]; then
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b $HOME
    zsh -c "$HOME/chezmoi init --source $SCRIPT_DIR/chezmoi --apply"
else 
    exit 0
fi