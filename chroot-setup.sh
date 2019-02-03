#!/bin/bash
#
# Copyright (c) 2019-2020 Thomas "Ventto" Venriès <thomas.venries@gmail.com>
#
set -e

TITLE()
{
    printf '\n#===================================#\n'
    printf '# %s\n' "$1"
    printf '#===================================#\n\n'
}

GRUB_INSTALL()
{
    TITLE "Step: ${FUNCNAME[0]}"

    ln -s /hostrun/lvm /run/lvm
    ls -l /run/lvm
    grub-install --efi-directory=/boot/efi
    grub-mkconfig -o /boot/grub/grub.cfg
    grub-mkconfig -o /boot/efi/EFI/arch/grub.cfg
}

SET_LOCALTIME()
{
    TITLE "Step: ${FUNCNAME[0]}"

    ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
    hwclock --systohc --utc
}

SET_LOCALE()
{
    TITLE "Step: ${FUNCNAME[0]}"

    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
    locale-gen
    echo "LANG=en_US.UTF-8" > /etc/locale.conf
}

SET_KEYBOARD_LANG()
{
    TITLE "Step: ${FUNCNAME[0]}"

    echo "KEYMAP=fr-latin1" > /etc/vconsole.conf
}

SET_HOSTNAME()
{
    TITLE "Step: ${FUNCNAME[0]}"

    echo "arch-laptop" > /etc/hostname
}

ADD_UDEV_RULES()
{
    TITLE "Step: ${FUNCNAME[0]}"

    mac="$(ip a l | grep -E -A 1 '^[0-9]+: enp.*: <.*' \
            | sed -n 's#link/ether \([0-9a-f]\{2\}\(:[0-9a-f]\{2\}\)\{5\}\) brd .*#\1#p' \
            | awk '{print $1}')"

    mkdir -p /etc/udev/rules.d/
    printf 'SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="%s", NAME="eth0"\n' \
           "$mac" > /etc/udev/rules.d/10-network.rules
    printf '# SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="00:11:22:33:44:55", NAME="wlo0"\n' \
            >> /etc/udev/rules.d/10-network.rules
}

ADD_USER()
{
    TITLE "Step: ${FUNCNAME[0]}"

    useradd -m -G wheel -s /bin/zsh ventto
    echo -n 'ventto:user' | chpasswd
}

SET_SUDOERS()
{
    TITLE "Step: ${FUNCNAME[0]}"

    pacman -S --noconfirm sudo
    sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers
}

DEL_BEEP()
{
    TITLE "Step: ${FUNCNAME[0]}"

    echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf
}

PACMAN_ENABLE_MULTILIB()
{
    TITLE "Step: ${FUNCNAME[0]}"

    echo "[multilib]" >> /etc/pacman.conf
    echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf

    pacman -Syu --noconfirm
}

INSTALL_PACMAN_USER_PKGS()
{
    TITLE "Step: ${FUNCNAME[0]}"

    wget -O pacman-list.pkg https://gist.githubusercontent.com/Ventto/104ccef45f20e424e78ac064d69e6551/raw/pacman-list.pkg

    pacman -S --noconfirm - < pacman-list.pkg
}

MAIN()
{
    {
        GRUB_INSTALL
        SET_LOCALTIME
        SET_LOCALE
        SET_KEYBOARD_LANG
        SET_HOSTNAME
        ADD_UDEV_RULES
        ADD_USER
        SET_SUDOERS
        DEL_BEEP
        PACMAN_ENABLE_MULTILIB
        INSTALL_PACMAN_USER_PKGS
    } 2>&1 | tee chroot-install.log
}

MAIN
