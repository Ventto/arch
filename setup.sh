#!/bin/bash
#
# Copyright (c) 2019-2020 Thomas "Ventto" Venriès <thomas.venries@gmail.com>
#
set -e

STORAGE_DEVICE="/dev/sda"
PARTITION_PREFIX=""
PASSPHRASE=

TITLE()
{
    printf '\n#===================================#\n'
    printf '# %s\n' "$1"
    printf '#===================================#\n\n'
}

ASK_MANUAL_PARAMETERS()
{
    TITLE "Step: ${FUNCNAME[0]}"

    printf "Enter passphrase for system encryption:"
    read_secret PASSPHRASE
    readonly PASSPHRASE
}

CHECK_CONNECTION()
{
    TITLE "Step: ${FUNCNAME[0]}"

    ping -c 3 google.com
}

SET_TIMEDATECTL()
{
    TITLE "Step: ${FUNCNAME[0]}"
    # Enable network time synchronization
    timedatectl set-ntp true
    timedatectl status
}

ERASING_DISK()
{
    TITLE "Step: ${FUNCNAME[0]}"

    # Erase the GPT at least and potentially the first bootable partition
    dd if=/dev/zero of="$STORAGE_DEVICE" bs=100M count=10 status=progress
}

CREATE_PARTITIONS()
{
    TITLE "Step: ${FUNCNAME[0]}"

    parted "$STORAGE_DEVICE" --script mklabel gpt
    parted "$STORAGE_DEVICE" --script mkpart ESP fat32 1MiB 200MiB
    parted "$STORAGE_DEVICE" --script set 1 boot on
    parted "$STORAGE_DEVICE" --script name 1 efi
    parted "$STORAGE_DEVICE" --script mkpart primary 800MiB 100%
    parted "$STORAGE_DEVICE" --script set 2 lvm on
    parted "$STORAGE_DEVICE" --script name 2 lvm
    parted "$STORAGE_DEVICE" --script print
}

read_secret()
{
    stty -echo
    trap 'stty echo' EXIT
    read "$@"
    stty echo
    trap - EXIT
    echo
}

ENCRYPT_SYSTEM()
{
    TITLE "Step: ${FUNCNAME[0]}"

    modprobe dm-crypt
    modprobe dm-mod

    # shellcheck disable=SC2154
    echo -n "$PASSPHRASE" | cryptsetup -q luksFormat "${STORAGE_DEVICE}${PARTITION_PREFIX}2" -
    echo -n "$PASSPHRASE" | cryptsetup luksOpen "${STORAGE_DEVICE}${PARTITION_PREFIX}2" lvm -
    pvcreate /dev/mapper/lvm
    vgcreate vg /dev/mapper/lvm
    lvcreate -L 1G vg -C y -n swap
    lvcreate -L 512M vg -n boot
    lvcreate -L 40G vg -n root
    lvcreate -l +100%FREE vg -n home
}

MAKEFS_PARTITIONS()
{
    TITLE "Step: ${FUNCNAME[0]}"

    mkswap -L swap /dev/mapper/vg-swap
    mkfs.ext4 /dev/mapper/vg-boot
    mkfs.ext4 /dev/mapper/vg-root
    mkfs.ext4 /dev/mapper/vg-home
    mkfs.fat -F32 "${STORAGE_DEVICE}${PARTITION_PREFIX}1"
}

MOUNT_PARTITIONS()
{
    TITLE "Step: ${FUNCNAME[0]}"

    swapon /dev/mapper/vg-swap
    mount /dev/mapper/vg-root /mnt
    mkdir /mnt/home
    mount /dev/mapper/vg-home /mnt/home
    mkdir /mnt/boot
    mount /dev/mapper/vg-boot /mnt/boot
    mkdir /mnt/boot/efi
    mount "${STORAGE_DEVICE}${PARTITION_PREFIX}1" /mnt/boot/efi

    lsblk
}

FILTER_MIRROR_FOR_PACKAGES()
{
    TITLE "Step: ${FUNCNAME[0]}"

    grep '## France' -A 1 /etc/pacman.d/mirrorlist \
        | grep -v '\-\-' > /etc/pacman.d/mirrorlist.new
    mv /etc/pacman.d/mirrorlist.new /etc/pacman.d/mirrorlist
}

INSTALL_ARCHLINUX_BASE_PACKAGES()
{
    TITLE "Step: ${FUNCNAME[0]}"
    pacstrap /mnt base base-devel wget vim efibootmgr grub --noconfirm
}

GENERATE_FSTAB()
{
    TITLE "Step: ${FUNCNAME[0]}"

    genfstab -U -p /mnt > /mnt/etc/fstab
}

CREATE_INITRD()
{
    TITLE "Step: ${FUNCNAME[0]}"

    sed -i 's#^HOOKS=(\(.*\))#HOOKS=(\1 encrypt lvm2)#' /mnt/etc/mkinitcpio.conf
    arch-chroot /mnt mkinitcpio -p linux
}

GRUB_SETUP_STEP_FIRST()
{
    TITLE "Step: ${FUNCNAME[0]}"

    sed -i "s#GRUB_CMDLINE_LINUX=\"\\(.*\\)\"#GRUB_CMDLINE_LINUX=\"cryptdevice=${STORAGE_DEVICE}${PARTITION_PREFIX}2:lvm\"#" \
        /mnt/etc/default/grub
    echo "GRUB_ENABLE_CRYPTODISK=y" >> /mnt/etc/default/grub

    ##
    # We need the lvmpad.socket to make `grub-mkconfig` command run properly
    # under chroot later
    mkdir /mnt/hostrun
    mount --bind /run /mnt/hostrun
}

RUN_CHROOT_SETUP()
{
    TITLE "Step: ${FUNCNAME[0]}"

    # Run the second script which runs commands under chroot
    cp ./chroot-setup.sh /mnt
    arch-chroot /mnt ./chroot-setup.sh \
        "${STORAGE_DEVICE}${PARTITION_PREFIX}2" "$PASSPHRASE"
}

REMOVE_ROOT_PASSWD()
{
    TITLE "Step: ${FUNCNAME[0]}"

    # Disable root's password
    passwd -R /mnt -l root
}

PRINT_RESUME()
{
    TITLE "Step: ${FUNCNAME[0]}"

    lsblk
    df -h | grep -E "Size|vg-|$(echo "$STORAGE_DEVICE" | cut -d/ -f3)"
}

SAVE_LOGS()
{
    TITLE "Step: ${FUNCNAME[0]}"

    mkdir -p /mnt/root/logs
    find . -maxdepth 1 -type f -name '*.log' -exec cp {} /mnt/root/logs \;
}

UMOUNT_PARTITIONS()
{
    TITLE "Step: ${FUNCNAME[0]}"

    umount -R /mnt
    swapoff -a
}

MAIN()
{
    # Display output in terminal and write it to a log file as well
    {
        ASK_MANUAL_PARAMETERS
        CHECK_CONNECTION
        SET_TIMEDATECTL
        ERASING_DISK
        CREATE_PARTITIONS
        ENCRYPT_SYSTEM
        MAKEFS_PARTITIONS
        MOUNT_PARTITIONS
        FILTER_MIRROR_FOR_PACKAGES
        INSTALL_ARCHLINUX_BASE_PACKAGES
        GENERATE_FSTAB
        CREATE_INITRD
        GRUB_SETUP_STEP_FIRST
        RUN_CHROOT_SETUP
        REMOVE_ROOT_PASSWD
        PRINT_RESUME
        SAVE_LOGS
        UMOUNT_PARTITIONS
    } 2>&1 | tee install.log
}

MAIN
