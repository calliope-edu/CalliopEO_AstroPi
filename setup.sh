#!/bin/bash

# Define variables
username="calliope" # name for user
groups="dialout" # group(s) the user has to be added

if [ "${EUID}" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# If command line argument is passed to script assume this is the username
# and overwrite variable ${username}
if [[ "${1}" != "" ]]; then
    username=${1}
fi

# If calliope user doesn't exist, create it
if ! id -u ${username} > /dev/null 2>&1; then
    useradd -m ${username}
fi

# Add user to groups in ${groups}. If user is already in the groups the
# command has no effect
usermod -a -G ${groups} ${username}

# Get user id and group id for later use
user_id=$(id -u ${username})
group_id=$(id -g ${username})

# Ask to provide/change password for user
read -p "Add/change password for ${username}? [yN]" ans
if [[ ${ans} =~ [Yy]$ ]]; then
    passwd ${username}
fi

# Determine UUIDs
uuid_mini=$(lsblk -o MODEL,UUID | grep -i "MSD[ -_]Volume" | awk '{print $2}')
uuid_flash=$(lsblk -o MODEL,UUID | grep -i "MSD[ -_]Flash" | awk '{print $2}')

# If the variables ${uuid_mini} and ${uuid_flash} are empty, some error
# occured (Calliope Mini not atached to Rasperry Pi). In this exit with error
# message
if [[ "${uuid_mini}" == "" || "${uuid_flash}" == "" ]]; then
    echo "Error detecting Calliope Mini. Exiting"
    exit 1
fi

# Create mount point in /etc/fstab that can be mounted by user calliope
mkdir -p /home/${username}/mnt/mini
mkdir -p /home/${username}/mnt/flash
chown -R ${user_id}:${group_id} /home/${username}/mnt

echo "# Mount points for Calliope Mini" >> /etc/fstab
echo "/dev/disk/by-uuid/${uuid_mini} /home/${username}/mnt/mini vfat noauto,users 0 0" >> /etc/fstab
echo "/dev/disk/by-uuid/${uuid_flash} /home/${username}/mnt/mini vfat noauto,users 0 0" >> /etc/fstab

# Install all Python modules from folder /modules
# First, copy the folder /modules to the home directory of ${username}.
# Then, install locally as user ${username}
cp -r ./modules/ /home/${username}/.
su - ${username} -c 'for m in ~/modules/*.whl; do python3 -m pip install --user ${m}; done'
# Clean up
rm -rf /home/${username}/modules

exit 0
