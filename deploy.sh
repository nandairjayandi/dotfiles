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

for script in "$SCRIPT_DIR"/deploy-scripts/[0-9][0-9]_*.sh; do
    script_name=$(basename "$script")
    print_info "Running $script_name..."
    $script
    drop_sudo
done