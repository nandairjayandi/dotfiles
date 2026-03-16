#!/bin/sh

. "$DOTFILES"/chezmoi/dot_local/bin/install-helper.sh

if [ "$(detect_os)" = "windows" ]; then
    print_error "Windows is not supported. Use WSL2 instead."
    exit 1
fi

if ! [ -w "$HOME" ]; then
    print_error "($HOME) is not writable. Cannot install Nix."
    exit 1
fi

if command_exists "nix"; then
    print_info "Nix already installed ($(nix --version)), skipping."
    exit 0
fi

check_nix_deps() {
    missing=""
    for cmd in curl tar xz; do
        command_exists "$cmd" || missing="$missing $cmd"
    done

    if [ -n "$missing" ]; then
        print_error "Missing required tools:$missing cannot proceed without root."
        return 1
    fi

    print_info "Nix dependencies satisfied (curl, tar, xz)."
}

prepare_nix_as_root() {
    pax_manager=$(detect_pax_manager)
    PATH="/usr/bin:/bin:$PATH"
    print_info "Installing Nix prerequisites using $pax_manager..."

    case "$pax_manager" in
        apt)        install_package -y xz-utils curl tar bash passwd coreutils ;;
        apk)        install_package -y xz curl tar bash shadow coreutils ;;
        dnf|yum)    install_package -y xz curl tar bash shadow-utils coreutils ;;
        pacman)     install_package -y xz curl tar bash shadow coreutils ;;
        brew)       install_package xz coreutils ;;
        *)          print_error "Unsupported package manager: $pax_manager"; return 1 ;;
    esac
}

install_nix() {
    os=$(detect_os)
    pax_manager=$(detect_pax_manager)

    case "$os" in
        macos)
            print_info "Installing Nix (macOS, multi-user)..."
            curl --proto '=https' --tlsv1.2 -sSfL https://nixos.org/nix/install | sh
            ;;
        *)
            if is_root; then
                print_info "Installing Nix (Linux, root, multi-user daemon)..."
                curl --proto '=https' --tlsv1.2 -sSfL https://nixos.org/nix/install | sh -s -- --daemon
            else
                print_info "Installing Nix (Linux, no root, single-user)..."
                curl --proto '=https' --tlsv1.2 -sSfL https://nixos.org/nix/install | sh -s -- --no-daemon
            fi
            ;;
    esac
}

source_nix() {
    if [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
        . "$HOME/.nix-profile/etc/profile.d/nix.sh"
    elif [ -e "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
        . "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
    else
        print_error "Could not find Nix profile script, installation may have failed."
        exit 1
    fi
}

if is_root; then
    prepare_nix_as_root || exit 1
else
    check_nix_deps      || exit 1
fi

install_nix  || exit 1
source_nix   || exit 1

exit 0