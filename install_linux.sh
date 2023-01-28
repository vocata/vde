#!/bin/bash

fmt_info() {
    printf '\033[32mInfo: %s\033[0m\n' "$*" >&1
}

fmt_error() {
    printf '\033[31mError: %s\033[0m\n' "$*" >&2
}

path_exists() {
    [[ :$PATH: == *:"$1":* ]]
}

error_handler() {
    fmt_error "installation incompleted, $*"
    exit 1
}

install_dependency() {
    sudo apt-get install -y \
        build-essential \
        cmake \
        curl \
        git \
        make \
        wget || {
        fmt_error "failed to install dependencies, check the error output to see how to fix it."
        return 1
    }
}

setup_omz() {
    fmt_info "installing zsh ..."
    sudo apt-get install -y zsh || {
        fmt_error "failed to install zsh."
        return 1
    }

    fmt_info "installing oh-my-zsh ..."
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --skip-chsh || {
        fmt_error "failed to install oh-my-zsh."
        return 1
    }

    [ -e "$HOME"/.zshrc ] || touch "$HOME"/.zshrc
    touch "$HOME"/.env && {
        echo -e "\n# Load custom setup"
        echo -e "[ -e \"\$HOME\"/.env ] && . \"\$HOME\"/.env\n"
    } >> "$HOME"/.zshrc

    [ -d "$HOME"/.local ] || mkdir -p "$HOME"/.local
}

setup_python3() {
    fmt_info "installing python3 ..."
    sudo apt-get install -y \
        python3 \
        python3-pip \
        python3-dev || {
        fmt_error "failed to install python3."
        return 1
    }

    bin_path_str="\"\$HOME\"/.local/bin"
    bin_path=$(eval "echo $bin_path_str")
    [ -d "$bin_path" ] || mkdir -p "$bin_path"
    # If not found in $PATH, append it.
    path_exists "$bin_path" || {
        export PATH="$PATH":"$bin_path"
        {
            echo -e "# Python3 setup"
            echo -e "export PATH=\"\$PATH\":$bin_path_str\n"
        } >> "$HOME"/.env
    }
}

setup_golang() {
    fmt_info "downloading golang package ..."
    version="go1.19.5"
    curl -fLo "$HOME"/.cache/golang/${version}.tar.gz --create-dirs \
        https://go.dev/dl/${version}.linux-amd64.tar.gz || {
        [ -e "$HOME"/.cache/golang/${version}.tar.gz ] && rm "$HOME"/.cache/golang/${version}.tar.gz
        fmt_error "failed to download golang package."
        return 1
    }

    fmt_info "installing golang ..."
    rm -rf "$HOME"/.local/go && tar -C "$HOME"/.local -xzf "$HOME"/.cache/golang/${version}.tar.gz

    go_path_str="\"\$HOME\"/.local/go/bin"
    go_path=$(eval "echo $go_path_str")
    bin_path_str="\"\$HOME\"/go/bin"
    bin_path=$(eval "echo $bin_path_str")
    [ -d "$go_path" ] || mkdir -p "$go_path"
    [ -d "$bin_path" ] || mkdir -p "$bin_path"
    path_exists "$go_path" || {
        export PATH="$PATH":"$go_path":"$bin_path"
        {
            echo -e "# Golang setup"
            echo -e "export PATH=\"\$PATH\":$go_path_str"
            echo -e "export PATH=\"\$PATH\":$bin_path_str\n"
        } >> "$HOME"/.env
    }
}

setup_rust() {
    fmt_info "installing rust ..."
    bash -c "$(curl -fsSL https://sh.rustup.rs)" || {
        fmt_error "failed to install rust."
        return 1
    }

    [ -e "$HOME"/.cargo/env ] && {
        . "$HOME"/.cargo/env
        {
            echo -e "# Rust setup"
            echo -e ". \"\$HOME\"/.cargo/env"
        } >> "$HOME"/.env
    }
}

setup_vim() {
    fmt_info "installing vim ..."
    sudo apt-get install -y vim-nox || {
        fmt_error "failed to install vim."
        return 1
    }

    fmt_info "installing vim-plug ..."
    curl -fLo "$HOME"/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim || {
        fmt_error "failed to download vim-plug, try again later."
        return 1
    }

    fmt_info "fetching vim configuration ..."
    git submodule update --init vimrc || {
        fmt_error "failed to clone vim configuration, try again later."
        return 1
    }

    fmt_info "creating .vimrc ..."
    [ -e "$HOME"/.vimrc ] && mv "$HOME"/.vimrc "$HOME"/.vimrc.old
    ln -s "$(pwd)"/vimrc/vimrc "$HOME"/.vimrc || {
        fmt_error "failed to create .vimrc."
        return 1
    }

    fmt_info "configuring YCM ..."
    vim -c "PlugInstall" && {
        # install YCM
        ycm_dir="$HOME"/.vim/plugged/YouCompleteMe
        fmt_info "YCM - installing clangd-completer ..."
        python3 "$ycm_dir"/install.py --clangd-completer
        fmt_info "YCM - installing go-completer ..."
        python3 "$ycm_dir"/install.py --go-completer
        fmt_info "YCM - installing rust-completer ..."
        python3 "$ycm_dir"/install.py --rust-completer
    }

    fmt_info "configuring LeaderF ..."
    fmt_info "LeaderF - installing ripgrep ..."
    cargo install ripgrep || {
        fmt_error "failed to install ripgrep."
        return 1
    }

    fmt_info "configuring ALE ..."
    fmt_info "ALE - installing pylint ..."
    pip3 install --user pylint || {
        fmt_error "failed to install pylint."
        return 1
    }
    fmt_info "ALE - installing clang ..."
    sudo apt-get install -y clang || {
        fmt_error "failed to install clang."
        return 1
    }
    fmt_info "ALE - installing gopls ..."
    go install golang.org/x/tools/gopls@latest || {
        fmt_error "failed to install gopls."
        return 1
    }
    fmt_info "ALE - installing shellcheck ..."
    sudo apt-get install -y shellcheck || {
        fmt_error "failed to install shellcheck."
        return 1
    }
    fmt_info "ALE - intalling vint ..."
    pip3 install --user vim-vint || {
        fmt_error "failed to install vint."
        return 1
    }

    fmt_info "configuring code-format ..."
    fmt_info "code-format - installing black ..."
    pip3 install --user black || {
        fmt_error "failed to intall black."
        return 1
    }
    fmt_info "code-format - installing clang-format ..."
    sudo apt-get install -y clang-format || {
        fmt_error "failed to install clang-format."
        return 1
    }
    fmt_info "code-format - installing shfmt ..."
    go install mvdan.cc/sh/v3/cmd/shfmt@latest || {
        fmt_error "failed to install shfmt."
        return 1
    }
}

main() {
    dist=$(cat /etc/issue)
    if [[ ! "$dist" =~ Ubuntu* ]] && [[ ! "$dist" =~ Debian* ]]; then
        fmt_error "only ubutu/debian is supported."
        exit 1
    fi

    fmt_info "starting install dependencies ..."
    install_dependency || error_handler "failed to install dependencies."

    fmt_info "starting setup oh-my-zsh ..."
    setup_omz || error_handler "failed to install oh-my-zsh"

    fmt_info "starting setup python3 ..."
    setup_python3 || error_handler "failed to install python3"

    fmt_info "starting setup golang ..."
    setup_golang || error_handler "failed to install golang"

    fmt_info "starting setup rust ..."
    setup_rust || error_handler "failed to install rust"

    fmt_info "starting setup vim ..."
    setup_vim || error_handler "failed to install vim"

    cs="Y"
    read -rp "change default shell to zsh? (Y/n)" cs
    if [ -z "$cs" ] || [ "${cs^^}" == "Y" ]; then
        chsh -s "$(which zsh)" && zsh
        exit 0
    fi
}

cd "$(dirname "$0")" && main "$@"
