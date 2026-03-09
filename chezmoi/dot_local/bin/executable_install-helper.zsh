#!/usr/bin/env zsh

# wrapper for install helper

source "${0:A:h}/install-helper.sh"

print_info() {
    print -P "%F{blue}[INFO]:%f $1"
}

print_error() {
    print -P "%F{red}[ERROR]:%f $1" >&2
}