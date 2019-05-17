#!/bin/bash
#
# Copyright (c) 2019-2020 Thomas "Ventto" Venriès <thomas.venries@gmail.com>
#
set -e
set -x

CURRENT_DIR="$(pwd)"

TITLE()
{
    printf '\n#===================================#\n'
    printf '# %s\n' "$1"
    printf '#===================================#\n\n'
}

UPDATE_PACKAGE_LIST()
{
    sudo pacman -Syu
}

INSTALL_YAY()
{
    TITLE "Step: ${FUNCNAME[0]}"

    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -sc --install --needed --noconfirm
}


INSTALL_AUR_PKGS()
{
    TITLE "Step: ${FUNCNAME[0]}"

    cd "$CURRENT_DIR"
    # FIXME: download a gist file
    test -r aur-pkgs.txt
    cat aur-pkgs.txt
    yay -Syu
    rm -f yay.log

    cat aur-pkgs.txt | while read -r pkg; do
        if yay -S --noconfirm "$pkg"; then
            echo "${pkg} - ok" >> yay.log
        else
            echo "${pkg} - failed" >> yay.log
        fi
    done
}

DOWNLOAD_DOTFILES()
{
    TITLE "Step: ${FUNCNAME[0]}"

    cd "$HOME"

    # Teardown
    rm -f "${HOME}/.config/dot"

    mkdir -p "${HOME}/.config/dot"
    git init --bare "${HOME}/.config/dot"
    dot="/usr/bin/git --git-dir=${HOME}/.config/dot --work-tree=${HOME}"
    $dot remote add origin https://github.com/Ventto/dot.git
    if ! $dot pull --rebase origin master; then
        $dot reset --hard origin/master
    fi
    printf "[include]\n\tpath = aliases\n" >> "${HOME}/.config/dot/config"
}

MAIN()
{
    # Display output in terminal and write it to a log file as well
    {
        UPDATE_PACKAGE_LIST
        INSTALL_YAY
        INSTALL_AUR_PKGS
        DOWNLOAD_DOTFILES
    } 2>&1 | tee install.log
}

MAIN
