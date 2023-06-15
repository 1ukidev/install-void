#!/usr/bin/env bash
set -e

scriptDirectory=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# UEFI
# Layout: GPT
# /dev/nvme0n1p1 - EFI
# /dev/nvme0n1p2 - GRUB
# /dev/nvme0n1p3 - VOID
cfdisk -z /dev/nvme0n1
mkfs.vfat -nEFI -F32 /dev/nvme0n1p1
mkfs.ext2 -L GRUB /dev/nvme0n1p2
cryptsetup luksFormat --type=luks -s=512 /dev/nvme0n1p3
cryptsetup open /dev/nvme0n1p3 cryptroot
mkfs.btrfs -f -L VOID --csum xxhash /dev/mapper/cryptroot

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
mount -o noatime /dev/nvme0n1p1 /mnt/efi
mkdir /mnt/boot
mount -o noatime /dev/nvme0n1p2 /mnt/boot

REPO=https://repo-fastly.voidlinux.org/current/
ARCH=x86_64
XBPS_ARCH=$ARCH xbps-install -S -y -r /mnt -R $REPO base-system btrfs-progs cryptsetup sudo

for dir in dev proc sys run; do mount --rbind /$dir /mnt/$dir; mount --make-rslave /mnt/$dir; done
cp /etc/resolv.conf /mnt/etc/

cp $scriptDirectory/chroot.sh /mnt/root/

BTRFS_OPTS=$BTRFS_OPTS PS1='(chroot) # ' chroot /mnt/ /bin/bash
