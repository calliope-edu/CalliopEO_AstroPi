# CalliopEO

## Description
CalliopEO is a Python script to facilitate ineraction between a Raspberry Pi microcomputer and a [Calliope Mini microcontroller board](https://calliope.cc/). If executed, the script detects, if a Calliope Mini is attached to a USB board of the Raspbery Pi and determins the serial port to communicate the Calliope Mini.

Place any program(s) to be executed by the Calliope Mini as zipped file(s) in the directory where the script `CalliopEO.py` resides. If executed the script will search for all zip archives, unpack the Calliope Mini program (HEX file) from the archive and flash the Calliope Mini with this program. After flashing, the Calliope Mini will reboot automatically and execute the program.

In the directory a sub-folder named `run_DDMMYY-HHMM` will be created. The HEX files flashed and executed on the Calliope Mini will be copied to this folder along with any data sent back by the program (files will end with `.data`). The initial zip archive in the main folder is renamed (additional suffix `.done`) to exclude this file from being processed again.

The `CalliopEO.py` script can collect data sent by the program on the Calliope Mini via the USB serial port. Therefore, prepare the Calliope Mini program to wait for the string `@START@`. Then, the Calliope Mini program should respond by sending `@START@` back to the CalliopEO.py` script and only after this sending the data. After sending the data the Calliope Mini program should send the
message `@END@`.

## Execute
It is recommended to use [`pipenv`](https://pipenv.pypa.io/en/latest/). If pipenv is in place and the Python virtual environment is established the script can be executed by:
```
$ pipenv run python CalliopEO.py
```

## Setup
The Calliope Mini should be connected via USB to the Raspberry Pi.
```
     +--------------+
     |              |      USB      o---o---o
     | Raspberry Pi |===============| Call. |
     |              |               o---o---o
     +--------------+                
```

## Raspberry Pi
### Operating system
Install the latest [Raspberry Pi OS](https://www.raspberrypi.org/software/) to the Raspberry Pi. For CalliopEO, the "OS Lite" version without desktop is sufficient. Follow the standard installation procedure.

### Create user calliope (optional)
In a terminal run the following comands to set up a user `calliope` and set the password:
```
$ sudo useradd -m -g dialout calliope
$ sudo passwd calliope
```
The user should be in the group `dialout` to access the serial port.

### Configure mount points in /etc/fstab
The Calliope Mini features to block devices, a mass storage volume and storage for the programs to be executed by the Calliope Mini microcontroller. To set-up mount poits in the Raspberry Pi's `/etc/fstab` determine the UUIDs of the mass storage volumes. Therefore, attach the Calliope Mini via USB to the Raspberry Pi and execute the command `lsblk`. Below, the command with typical output is
given.
```
$ lsblk -o UUID,MODEL
NAME        MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT UUID                                 MODEL
sda           8:0    1 10.7M  0 disk            0123-4567                            MSD_Volume
sdb           8:16   1   16M  0 disk            089A-BCDE                            MSD_FLASH
mmcblk0     179:0    0 29.7G  0 disk
├─mmcblk0p1 179:1    0  256M  0 part /boot      5DE4-665C
└─mmcblk0p2 179:2    0 29.5G  0 part /          7295bbc3-bbc2-4267-9fa0-099e10ef5bf0
```
In the above example, the two Calliope Mini mass storage devices are `/dev/sda` and `/dev/sdb` with the UUID `0123-4567` and `089A-BCDE`, respectively. Now, we can edit the file `/etc/fstab` and add two new entries:
```
# Calliope Mini
/dev/disk/by-uuid/0123-4567 /home/calliope/mnt/mini vfat noauto,users 0 0
/dev/disk/by-uuid/089A-BCDE /home/calliope/mnt/flash vfat noauto,users 0 0<Paste>
```
Finally, we create the mount points in the user directory of the user `calliope`. Therefore, execute as user `calliope`:
```
mkdir -p ~/mnt/mini
mkdir -p ~/mnt/flash
```

### Install dependencies
The CalliopEO Python script has very few dependencies. At minimum, you need:
* Python 3
* [pySerial](https://pyserial.readthedocs.io/en/latest/pyserial.html) module
* [blkinfo](https://pypi.org/project/blkinfo/) module

It is recommended to install [`pipenv`](https://pipenv.pypa.io/). With `pipenv` in place you can create a Python virtual environment equipped with all dependencies:
```
$ pipenv install
$ pipenv sync
```

