#!/bin/bash

fmt_info() {
    printf '\033[32mInfo\033[0m: %s\n' "$*" >&1
}

fmt_error() {
    printf '\033[31mError\033[0m: %s\n' "$*" >&2
}

command_exists() {
    command -v "$@" > /dev/null 2>&1
}

install_prerequisite() {
    command_exists brew || {
        fmt_error "brew is not installed"
        exit 1
    }

    brew install \
        black \
        cmake \
        curl \
        git \
        go \
        pylint \
        python \
        llvm \
        ripgrep \
        rust \
        rustfmt \
        shellcheck \
        shfmt \
        staticcheck \
        vim \
        vint \
        zsh || {
        fmt_error "failed to install prerequisite, check the error output to see how to fix it"
        exit 1
    }
}

setup_vim() {
    fmt_info "starting setup vim ..."

    fmt_info "installing vim-plug ..."
    curl -fLo "$HOME"/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim || {
        fmt_error "failed to download vim-plug, try again later"
        exit 1
    }
    fmt_info "vim-plug installation succeed."

    fmt_info "cloning vim configuration ..."
    git submodule update --init vimrc || {
        fmt_error "failed to clone vimrc, tray again later"
        exit 1
    }
    fmt_info "vim configuration clone succeed."

    fmt_info "creating .vimrc ..."
    [ -e "$HOME"/.vimrc ] && mv "$HOME"/.vimrc "$HOME"/.vimrc.old
    ln -s "$(pwd)"/vimrc/vimrc "$HOME"/.vimrc
    fmt_info ".vimrc creation succeed."

    fmt_info "install YouCompleteMe ..."
    vim -c PlugInstall && {
        # install YCM
        ycm_dir="$HOME"/.vim/plugged/YouCompleteMe
        python3 "$ycm_dir"/install.py --clangd-completer
        python3 "$ycm_dir"/install.py --go-completer
        python3 "$ycm_dir"/install.py --rust-completer
    }
    fmt_info "YouCompleteMe installation succeed."

    fmt_info "vim setup finished."
}

setup_omz() {
    fmt_info "starting setup oh-my-zsh ..."

    fmt_info "installing oh-my-zsh ..."
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || {
        fmt_error "failed to install oh-my-zsh"
        exit 1
    }
    fmt_info "oh-my-zsh installation succeed."

    fmt_info "oh-my-zsh setup finished."
}

main() {
    install_prerequisite
    setup_omz
    setup_vim
}

cd "$(dirname "$0")" && main "$@"
