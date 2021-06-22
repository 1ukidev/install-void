set -e

vi /etc/hostname
vi /etc/rc.conf
vi /etc/default/libc-locales
xbps-reconfigure -f glibc-locales

passwd

BTRFS_OPTS="rw,noatime,discard,ssd,compress=zstd,space_cache,commit=120"
UEFI_UUID=$(blkid -s UUID -o value /dev/sda1)
GRUB_UUID=$(blkid -s UUID -o value /dev/sda2)
ROOT_UUID=$(blkid -s UUID -o value /dev/mapper/cryptroot)
printf "UUID=$ROOT_UUID / btrfs $BTRFS_OPTS,subvol=@ 0 1\nUUID=$UEFI_UUID /efi vfat defaults,noatime 0 2\nUUID=$GRUB_UUID /boot ext2 defaults,noatime 0 2\nUUID=$ROOT_UUID /home btrfs $BTRFS_OPTS,subvol=@home 0 2\nUUID=$ROOT_UUID /.snapshots btrfs $BTRFS_OPTS,subvol=@snapshots 0 2\ntmpfs /tmp tmpfs defaults,nosuid,nodev 0 0" >> /etc/fstab

echo hostonly=yes >> /etc/dracut.conf

xbps-install -Su -y void-repo-nonfree
xbps-install -S -y intel-ucode

xbps-install -y grub-x86_64-efi
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
