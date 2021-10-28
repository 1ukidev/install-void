# Install Void
Shell script to install Void Linux.<br>
- Btrfs with Zstandard compression
- LUKS-encrypted root and swapfile
- GRUB with UEFI
- Optimized for SSD

## Partitions order
- /dev/sda1 - EFI
- /dev/sda2 - GRUB
- /dev/sda3 - Void Linux

## Reference
https://gist.github.com/gbrlsnchs/9c9dc55cd0beb26e141ee3ea59f26e21
