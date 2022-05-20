#!/usr/bin/env bash
set -e

vi /etc/hostname
vi /etc/rc.conf
vi /etc/default/libc-locales
vi /etc/locale.conf
xbps-reconfigure -f glibc-locales
passwd

BTRFS_OPTS="noatime,discard=async,compress=zstd,space_cache=v2,autodefrag"
UEFI_UUID=$(blkid -s UUID -o value /dev/sda1)
GRUB_UUID=$(blkid -s UUID -o value /dev/sda2)
ROOT_UUID=$(blkid -s UUID -o value /dev/mapper/cryptroot)
printf "UUID=$ROOT_UUID / btrfs $BTRFS_OPTS,subvol=@ 0 1\nUUID=$UEFI_UUID /efi vfat ro,defaults,noatime 0 2\nUUID=$GRUB_UUID /boot ext2 defaults,noatime 0 2\nUUID=$ROOT_UUID /home btrfs $BTRFS_OPTS,subvol=@home 0 2\nUUID=$ROOT_UUID /.snapshots btrfs $BTRFS_OPTS,subvol=@snapshots 0 2\n/var/swap/swapfile none swap sw 0 0\n" >> /etc/fstab
echo hostonly=yes >> /etc/dracut.conf

mkdir /etc/xbps.d
cp /usr/share/xbps.d/*-repository-*.conf /etc/xbps.d/
sed -i 's|https://alpha.de.repo.voidlinux.org|https://mirrors.servercentral.com/voidlinux/|g' /etc/xbps.d/*-repository-*.conf

xbps-install -Su -y void-repo-nonfree void-repo-multilib 
xbps-install -S -y intel-ucode grub-x86_64-efi

grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id="Void Linux"

truncate -s 0 /var/swap/swapfile
chattr +C /var/swap/swapfile
btrfs property set /var/swap/swapfile compression none
chmod 600 /var/swap/swapfile
dd if=/dev/zero of=/var/swap/swapfile bs=1G count=4 status=progress
mkswap /var/swap/swapfile
swapon /var/swap/swapfile

xbps-reconfigure -fa
rm -rf /var/cache/xbps
rm /root/chroot.sh

IFS= read -rp "Enter username: " username
IFS= read -rp "Enter name: " name 
useradd -m -G wheel,input,video,audio -s /bin/bash -c "$name" $username
passwd $username
visudo

printf "\n\nVoid Linux successfully installed!\n\n"
