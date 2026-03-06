#!/usr/bin/env zsh

# docker compose run --remove-orphans --build --rm dotfiles-alpine sh -c "./bootstrap.sh && exec zsh"

execute() {
    docker compose run --remove-orphans --build --rm $1 sh -c "./bootstrap.sh && exec zsh"
}

execute_alpine() {
    execute "dotfiles-alpine"
}

execute_ubuntu_non_root() {
    execute "dotfiles-ubuntu-non-root"
}

execute_ubuntu_root() {
    execute "dotfiles-ubuntu-root"
}