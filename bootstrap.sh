#!/bin/sh

#### Start Bootstrap ####

set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)" && . "$DOTFILES"/chezmoi/dot_local/bin/executable_install-helper.sh
OS=$(detect_os)
PAX_MANAGER=$(detect_pax_manager)

export OS PAX_MANAGER DOTFILES

print_info "OS=$OS"
print_info "PAX_MANAGER=$PAX_MANAGER"
print_info "$DOTFILES"

update_pax_manager
install_package  -y curl git zsh bash 

# for boot_script in "bin/"*; do
#     . "$boot_script"
# done

# sh -c "00_install-nix.sh"

# git clone --depth=1 https://github.com/mattmc3/antidote.git ${ZDOTDIR:-$HOME}/.antidote
# sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --no-daemon

if [ "$(get_bool "Handoff to Chezmoi?" "Y")" = "Y" ]; then
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b $HOME
    zsh -c "$HOME/chezmoi init --source $DOTFILES/chezmoi --apply"
else 
    exit 0
fi