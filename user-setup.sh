#!/bin/bash
#
# Copyright (c) 2019-2020 Thomas "Ventto" Venriès <thomas.venries@gmail.com>
#
set -e
set -x

LOG_AUR_INSTALL="${HOME}/yay.log"
LOG_SCRIPT="${HOME}/install.log"
CURRENT_DIR="$(pwd)"

TITLE()
{
    printf '\n#===================================#\n'
    printf '# %s\n' "$1"
    printf '#===================================#\n\n'
}

RUN_DHCPCD_ETH0()
{
    sudo dhcpcd eth0
}

UPDATE_PASSWD()
{
    passwd
}

UPDATE_PACKAGE_LIST()
{
    sudo pacman -Syu
}

INSTALL_YAY()
{
    TITLE "Step: ${FUNCNAME[0]}"

    cd /tmp
    rm -rf yay/
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

    echo "The following AUR packages will be installed:"
    cat aur-pkgs.txt
    yay -Syu
    rm -f "$LOG_AUR_INSTALL"

    cat aur-pkgs.txt | while read -r pkg; do
        if yay -S --noconfirm "$pkg"; then
            echo "${pkg} - ok" >> "$LOG_AUR_INSTALL"
        else
            echo "${pkg} - failed" >> "$LOG_AUR_INSTALL"
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

COMPLETE_TOOL_CONFIGS()
{
    TITLE "Step: ${FUNCNAME[0]}"

    set -x

    # Setup group permission for lux
    sudo lux >/dev/null 2>&1

    # Install neovim plugins
    nvim +PlugInstall +qall

    # Restore own pin tabs
    make -C "${HOME}/.config/firefox/.make/"

    # Build smplayer theme
    make -C "${HOME}/.config/smplayer/contrib"

    set +x
}

MAIN()
{
    # Display output in terminal and write it to a log file as well
    {
        RUN_DHCPCD_ETH0
        UPDATE_PASSWD
        UPDATE_PACKAGE_LIST
        INSTALL_YAY
        INSTALL_AUR_PKGS
        DOWNLOAD_DOTFILES
        COMPLETE_TOOL_CONFIGS
    } 2>&1 | tee "$LOG_SCRIPT"
}

MAIN

# To apply the change for the next session
exit
