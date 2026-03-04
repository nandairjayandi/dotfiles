#!/bin/sh

[ -z "$BOOTSTRAP_HELPER" ] && BOOTSTRAP_HELPER=bootstrap_helper.sh

. $BOOTSTRAP_HELPER

if [ "$(detect_os)" != "darwin" ]; then
    return
fi