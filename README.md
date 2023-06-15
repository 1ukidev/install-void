# Install Void
Shell script to install Void Linux.

**WARNING: don't run the script without understanding it first! This script is destructive!**

- Btrfs with Zstandard compression
- LUKS-encrypted root and swapfile
- GRUB with UEFI
- Optimized for SSD

## Partitions order
- /dev/nvme0n1p1 - EFI
- /dev/nvme0n1p2 - GRUB
- /dev/nvme0n1p3 - Void Linux

## Reference
https://gist.github.com/gbrlsnchs/9c9dc55cd0beb26e141ee3ea59f26e21
