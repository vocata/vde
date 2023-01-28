#!/bin/bash

command_exists() {
    command -v "$@" > /dev/null 2>&1
}

main() {
    command_exists git || {
        echo "git is not installed" >&2
        exit 1
    }

    repo_dir="$HOME"/.dotfiles
    git clone --depth 1 --branch main "https://github.com/vocata/dotfiles.git" "$repo_dir" && cd "$repo_dir" || exit 1

    os=$(uname -s)
    case "$os" in
        Linux) script=./install_linux.sh ;;
        Darwin) script=./install_macos.sh ;;
        *) echo "unknown system: $os" >&2 && exit 1 ;;
    esac

    # Execute installation script
    bash "$script" || {
        echo "installation failed." >&2
        exit 1
    }
}

cd "$(dirname "$0")" && main "$@"
