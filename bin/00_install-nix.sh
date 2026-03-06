#!/bin/sh

. "$DOTFILES"/chezmoi/dot_local/bin/executable_install-helper.sh
if is_root; then
    # https://nixos.org/download/#nix-install-linux
    print_info "Installing Nix in multi-user"
    sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon
elif command_exists sudo; then 
    print_info "Installing Nix as multi-user"
    request_sudo
    sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon
else
    sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --no-daemon
fi
# sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --no-daemon