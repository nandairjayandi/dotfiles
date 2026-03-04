#!/bin/sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BOOTSTRAP_HELPER="$SCRIPT_DIR"/deploy-scripts/bootstrap-helper.sh && . $BOOTSTRAP_HELPER # instead of source posix uses .
OS=$(detect_os)
PAX_MANAGER=$(detect_pax_manager)

export OS PAX_MANAGER BOOTSTRAP_HELPER

print_info "OS=$OS"
print_info "PAX_MANAGER=$PAX_MANAGER"
print_info "$SCRIPT_DIR"

# Default XDG paths
export XDG_CACHE_HOME="$HOME"/.cache
export XDG_CONFIG_HOME="$HOME"/.config
export XDG_DATA_HOME="$HOME"/.local/share
export XDG_STATE_HOME="$HOME"/.local/state

print_info "Checking for ZDOTDIR env variable..."
if [ -n "$ZDOTDIR" ] && [ "$ZDOTDIR" = "$SCRIPT_DIR/zsh" ]; then
    print_info "  ...present and valid, skipping .zshenv symlink"
else
    print_info "  ...failed to match this script dir. ZDOTDIR is \"%s\", which doesn't match expected value \"%s/zsh\". Symlinking .zshenv\n" "$ZDOTDIR" "$SCRIPT_DIR"
    
    ZDOTDIR_TARGET="${ZDOTDIR:-$HOME}"
    ln -sf "$SCRIPT_DIR/zsh/.zshenv" "$ZDOTDIR_TARGET/.zshenv"
fi

for script in "$SCRIPT_DIR"/deploy-scripts/[0-9][0-9]_*.sh; do
    script_name=$(basename "$script")
    print_info "Running $script_name..."
    $script
    drop_sudo
done

if [ "$(get_bool "Handoff to chezmoi?" "Y")" = "Y" ]; then
    chezmoi init --source "$SCRIPT_DIR"/chezmoi --apply
else 
    exit 0
fi