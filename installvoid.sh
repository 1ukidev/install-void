#!/usr/bin/env bash
set -e

# UEFI
# Layout: GPT
# /dev/sda1 - EFI
# /dev/sda2 - GRUB
# /dev/sda3 - VOID

cfdisk -z /dev/sda
mkfs.vfat -nBOOT -F32 /dev/sda1
mkfs.ext2 -L GRUB /dev/sda2
cryptsetup luksFormat --type=luks -s=512 /dev/sda3
cryptsetup open /dev/sda3 cryptroot
mkfs.btrfs -f -L VOID /dev/mapper/cryptroot

BTRFS_OPTS="noatime,discard=async,compress=zstd,space_cache=v2,autodefrag"
mount -o $BTRFS_OPTS /dev/mapper/cryptroot /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
umount /mnt
mount -o $BTRFS_OPTS,subvol=@ /dev/mapper/cryptroot /mnt
mkdir /mnt/home
mount -o $BTRFS_OPTS,subvol=@home /dev/mapper/cryptroot /mnt/home
mkdir /mnt/.snapshots
mount -o $BTRFS_OPTS,subvol=@snapshots /dev/mapper/cryptroot /mnt/.snapshots
mkdir -p /mnt/var/cache
btrfs subvolume create /mnt/var/cache/xbps
btrfs subvolume create /mnt/var/tmp
btrfs subvolume create /mnt/srv
btrfs subvolume create /mnt/var/swap
mkdir /mnt/efi
mount -o noatime /dev/sda1 /mnt/efi
mkdir /mnt/boot
mount -o noatime /dev/sda2 /mnt/boot

REPO=https://mirrors.servercentral.com/voidlinux/current
ARCH=x86_64
XBPS_ARCH=$ARCH xbps-install -S -y -R "$REPO" -r /mnt base-system btrfs-progs cryptsetup sudo zsh

for dir in dev proc sys run; do mount --rbind /$dir /mnt/$dir; mount --make-rslave /mnt/$dir; done
cp /etc/resolv.conf /mnt/etc/

cp ./install-void/chroot.sh /mnt/root/

BTRFS_OPTS=$BTRFS_OPTS PS1='(chroot) # ' chroot /mnt/ /bin/bash
