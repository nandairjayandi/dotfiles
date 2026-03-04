#!/bin/sh

[ -z "$BOOTSTRAP_HELPER" ] && BOOTSTRAP_HELPER=bootstrap_helper.sh

. $BOOTSTRAP_HELPER

install_package -p "$PAX_MANAGER" git curl chezmoi

