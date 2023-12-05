DISK=/dev/sda
MAPPER=/dev/mapper/crypted

sudo parted "$DISK" -- mklabel gpt
sudo parted "$DISK" -- mkpart ESP fat32 1MiB 512MiB
sudo parted "$DISK" -- set 1 esp on
sudo mkfs.fat -F 32 -n BOOT  "$DISK"1 

# As I intend to use this VM on Proxmox, I will not encrypt the disk

sudo parted "$DISK" -- mkpart Swap linux-swap 512MiB 4GiB
sudo mkswap -L SWAP "$DISK"2
sudo swapon "$DISK"2

sudo parted "$DISK" -- mkpart primary 4GiB 100%
# encrypt
sudo cryptsetup luksFormat "$DISK"3
sudo cryptsetup luksConfig "$DISK"3 --label NIXOS
sudo cryptsetup luksOpen "$DISK"3 crypted 

sudo mkfs.btrfs -L Butter "$MAPPER"

sudo mount "$MAPPER" /mnt
sudo btrfs subvolume create /mnt/root
sudo btrfs subvolume create /mnt/home
sudo btrfs subvolume create /mnt/nix
sudo btrfs subvolume create /mnt/persist
sudo btrfs subvolume create /mnt/log

# We then take an empty *readonly* snapshot of the root subvolume,
# which we'll eventually rollback to on every boot.
sudo btrfs subvolume snapshot -r /mnt/root /mnt/root-blank

sudo umount /mnt

# Mount the directories

sudo mount -o subvol=root,compress=zstd,noatime "$Mapper" /mnt

sudo mkdir /mnt/home
sudo mount -o subvol=home,compress=zstd,noatime "$Mapper" /mnt/home

sudo mkdir /mnt/nix
sudo mount -o subvol=nix,compress=zstd,noatime "$Mapper" /mnt/nix

sudo mkdir /mnt/persist
sudo mount -o subvol=persist,compress=zstd,noatime "$Mapper" /mnt/persist

sudo mkdir -p /mnt/var/log
sudo mount -o subvol=log,compress=zstd,noatime "$Mapper" /mnt/var/log

# don't forget this!
sudo mkdir /mnt/boot
sudo mount "$DISK"1 /mnt/boot

# create configuration
sudo nixos-generate-config --root /mnt

# now, edit nixos configuration and nixos-install
