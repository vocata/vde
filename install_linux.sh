#!/bin/bash

fmt_info() {
    printf 'Info: %s\n' "$*" >&1
}

fmt_error() {
    printf 'Error: %s\n' "$*" >&2
}

command_exists() {
    command -v "$@" > /dev/null 2>&1
}

install_prerequisite() {
    DbEBIAN_FRONTEND=noninteractive sudo apt-get install -y \
        black \
        build-essential \
        cargo \
        clang \
        clang-format \
        cmake \
        curl \
        git \
        golang-1.18 \
        pylint \
        python3 \
        python3-pip \
        python3-dev \
        rustfmt \
        shellcheck \
        vim \
        zsh || {
        fmt_error "failed to install prerequisite, check the error output to see how to fix it"
        exit 1
    }

    # fix soft link to golang-1.18
    sudo update-alternatives --install /usr/bin/go golang /usr/lib/go-1.18/bin/go 0

    # missing shfmt, staticcheck and vint
    go install honnef.co/go/tools/cmd/staticcheck@latest || {
        fmt_error "failed to install staticcheck"
        exit 1
    }
    go install mvdan.cc/sh/v3/cmd/shfmt@latest || {
        fmt_error "failed to install shfmt"
        exit 1
    }
    pip3 install --user vim-vint || {
        fmt_error "failed to install vim-vint"
        exit 1
    }
}

setup_vim() {
    fmt_info "starting set up vim ..."

    fmt_info "installing vim-plug ..."
    curl -fLo "$HOME"/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim || {
        fmt_error "failed to download vim-plug, try again later"
        exit 1
    }
    fmt_info "succeed."

    fmt_info "cloning vimrc ..."
    git submodule update --init vimrc || {
        fmt_error "failed to clone vimrc, tray again later"
        exit 1
    }
    fmt_info "succeed."

    fmt_info "creating .vimrc ..."
    [ -e "$HOME"/.vimrc ] && mv "$HOME"/.vimrc "$HOME"/.vimrc.old
    ln -s "$(pwd)"/vimrc/vimrc "$HOME"/.vimrc
    fmt_info "succeed."

    fmt_info "install YouCompleteMe ..."
    vim -c PlugInstall && {
        # install YCM
        ycm_dir="$HOME"/.vim/plugged/YouCompleteMe
        python3 "$ycm_dir"/install.py --clangd-completer
        python3 "$ycm_dir"/install.py --go-completer
        python3 "$ycm_dir"/install.py --rust-completer
    }
    fmt_info "succeed."

    fmt_info "vim setup finished."
}

setup_omz() {
    fmt_info "starting set up oh-my-zsh ..."

    fmt_info "installing oh-my-zsh ..."
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || {
        fmt_error "failed to install oh-my-zsh"
        exit 1
    }
    fmt_info "succeed."

    fmt_info "oh-my-zsh setup finished."
}

main() {
    opt_vim=0
    opt_omz=0
    # parse arguments
    while [ $# -gt 0 ]; do
        case $1 in
            --omz) opt_omz=1 ;;
            --vim) opt_vim=1 ;;
            --all)
                opt_omz=1
                opt_vim=1
                ;;
        esac
        shift
    done

    [ $opt_omz -eq 1 ] || [ $opt_vim -eq 1 ] && install_prerequisite
    [ $opt_omz -eq 1 ] && setup_omz
    [ $opt_vim -eq 1 ] && setup_vim
}

cd "$(dirname "$0")" && main "$@"
