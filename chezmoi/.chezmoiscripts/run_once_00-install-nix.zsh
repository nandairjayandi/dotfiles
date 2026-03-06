#!/bin/sh

. "$DOTFILES"/chezmoi/dot_local/bin/executable_install-helper.sh

if [ $detect_os -eq "windows" ]; then
    exit 1
fi

install_xz_for_nix() {
    local pax_manager
    pax_manager=$(detect_pax_manager)
    
    case "$pax_manager" in
        apt)         install_package xz-utils ;;
        apk)         install_package -y -p apk xz ;;
        dnf|yum)     install_package -y -p "$pax_manager" xz ;;
        pacman)      install_package -y -p pacman xz ;;
        brew)        install_package -p brew xz ;;
        *)
        # note that you can't install nix natively on windows so scoop/choco/winget wouldn't function here
            print_error "Don't know how to install xz on $pax_manager"
            return 1
            ;;
    esac
}

if ! command_exists xz; then
    install_xz_for_nix
fi

if is_root || command_exists sudo; then
    # https://nixos.org/download/#nix-install-linux
    print_info "Installing Vanilla Nix as multi-user"
    curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install --daemon
else
    print_info "Installing Vanilla Nix single-user"
    curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install --no-daemon
fi

exec zsh
# sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --no-daemon