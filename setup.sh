#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit 1
fi

# Create user calliope
useradd -m -g dialout calliope

# Specify password for user calliope
passwd calliope

# Determine UUIDs
uuid_mini=$(lsblk -o MODEL,UUID | grep -i "MSD[ -_]Volume" | awk '{print $2}')
uuid_flash=$(lsblk -o MODEL,UUID | grep -i "MSD[ -_]Flash" | awk '{print $2}')

# Create mount point in /etc/fstab that can be mounted by user calliope
mkdir -p /home/calliope/mnt/mini
mkdir -p /home/calliope/mnt/flash
chown -R calliope:calliope /home/calliope/mnt

echo "# Mount points for Calliope Mini" >> /etc/fstab
echo "/dev/disk/by-uuid/${uuid_mini} /home/calliope/mnt/mini vfat noauto,users 0 0" >> /etc/fstab
echo "/dev/disk/by-uuid/${uuid_flash} /home/calliope/mnt/mini vfat noauto,users 0 0" >> /etc/fstab

# Install all Python modules from folder /modules
for module in ./modules/*.whl; do
    python3 -m pip install --user ${module}
done
