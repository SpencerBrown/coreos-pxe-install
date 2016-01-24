# Create an Arch Linux utility machine

## Acquire a machine

It should:

* be capable of running on its own without a keyboard/mouse
* have two network adapters, one set up for DHCP-fueled access to the Internet, one facing inward to the cluster it's managing
* have a reasonably new Intel 64-bit multicore CPU
* have a reasonably modern motherboard that supports UEFI boot
* have a reasonable size/number of disk drives. SSDs are very nice.
* have at least 4GB memory

## Installing Arch Linux

Generally, follow the directions in the [Beginners' Guide](https://wiki.archlinux.org/index.php/Beginners'_guide) or the [Installation Guide](https://wiki.archlinux.org/index.php/Installation_guide).

### Create the install media

1. Download the Arch Linux ISO from [Rackspace](http://mirror.rackspace.com/archlinux/iso) or another [mirror site](https://wiki.archlinux.org/index.php/Mirrors).
2. If installing on a real machine, burn the ISO to a USB flash drive or CD-R disk.

#### How to burn the .iso file to a USB flash drive using OS X

1. Run `diskutil list`, then insert the flast drive and run `diskutil list` again.
2. Figure out its device name by noting the differences in the lists.
3. Let's say its device name is `/dev/disk2`, adjust the following as needed.
4. `diskutil unmountDisk /dev/disk2` to unmount the mounted partitions.
5. NOTE THE USE OF `/dev/rdisk2` instead of `/dev/disk2` in the next step.
6. VERY CAREFULLY: MAKE SURE YOUR DEVICE NAME FOR `of=` IS CORRECT OR YOU MAY DESTROY YOUR SYSTEM:
7. `sudo dd if=~/Downloads/archlinux-2015.12.01-dual.so of=/dev/rdisk2 bs=1m`
8. `diskutil eject /dev/disk2`
9. Remove the drive.

### Install basic Arch Linux

Connect (temporarily) a keyboard and display to your machine. Boot the machine into its BIOS settings. (Typically you press the Delete or F2 key several times after booting.)

Or, many machines now support a special "boot override" mode which does a one-time boot from a specified device, without changing the BIOS defaults.
Try F11 for this, or see the display on your screen from the BIOS for a hint.

Adjust the machine's BIOS settings to boot from your media, selecting the UEFI boot if available. 

Select the 64-bit version to run, if you are given a choice.

#### Initial setup

`ping google.com` to ensure you have Internet connectivity.

`timedatectl set-ntp true` to sync your clock.

Run `lsblk` and decide which disk is going to be your boot drive. It will be completely overwritten.

#### Partition and format the boot drive

In this example the boot drive is `/dev/sda`, adjust accordingly. It will be completely overwritten, all existing data will be lost.

We will create two partitions. Partition 1 is the EFI system partition for booting Arch Linux via UEFI boot.
Partition 2 is a Linux partition where the system resides.

to reset the disk and create the EFI system partition:
```
sgdisk --zap-disk /dev/sda
gdisk /dev/sda
o    (overwrite partition table)
n    (create new partition)
(enter)    (accept default partiton 1)
<enter>    (accept default start)
512M       (partition size 512 megabytes)
ef00       (partition type EFI System)
w          (write to disk)
y          (proceed)
mkfs.fat -F32 /dev/sda1
```

to create the Linux partition:

```
gdisk /dev/sda
n      (create new partition)
<enter> 4 times  (accept all the defaults)
w      (write to disk)
y      (proceed)
mkfs.ext4 /dev/sda2
```

#### Set up mirror list

The mirror list determines where Arch Linux installation will go to download packages.
You can use the mirror list as is but it will probably use a very slow website.

```
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.original    (save original mirror list)
vim /etc/pacman.d/mirrorlist
%s:/Server =/#Server =/    (comment out all the servers)
     (now locate servers you like and uncomment those lines... rackspace is usually a good choice)
:wq
```

#### Download packages

```
mount /dev/sda2 /mnt       (adjust partition name as needed)
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot
pacstrap /mnt base base-devel     (this will download and install a bunch of packages)
```

#### Basic configuration of the new system

This sets up the disk mount table, clock, timezone, and locale.
Then we set up the network adapter, and basic configuration of the UEFI boot partition.

```
genfstab -p /mnt >> /mnt/etc/fstab    (generate initial mount table)
arch-chroot /mnt                      (enter the new system's directory tree)
echo utility > /etc/hostname          (sub your desired hostname for "utility")  
ln -s /usr/share/zoneinfo/US/Central /etc/localtime      (set local time zone, modify "Central" as appropriate)
hwclock --systohc --utc               (set hardware clock to system time in UTC)
vi /etc/locale.gen                   (set default locale)
(Uncomment line "#  en_US.UTF-8 UTF-8", and save)
locale-gen                           (generate the new locale information)
echo LANG=en_US.UTF-8 > /etc/locale.conf     (set the default locale)
ip addr                     (list installed network adapters)
(pick the adapter that's connected to the Internet, we use "enp4s0" in this example)
systemctl enable dhcpcd@enp4s0.service      (enable DHCP on adapter at boot)
mkinitcpio -p linux                   (create Linux initial boot binary)
passwd                                (set a root password)
(enter a root password twice)
bootctl install             (install UEFI boot structure to /boot)
exit      (return to the base system)
```

#### Create boot configuration

`vim /mnt/boot/loader/entries/arch.conf` to create a new boot configuration file with the following contents.
Of course, adjust `/dev/sda2` to reflect your boot partition.

```
title          Arch Linux
linux          /vmlinuz-linux
initrd         /initramfs-linux.img
options        root=/dev/sda2 rw
```

`vim /mnt/boot/loader/loader.conf` to point the EFO bootloader to the new `arch.conf`.

Replace the line starting with `default` with:

`default arch`

#### Boot the new system

Remove the USB drive and `systemctl reboot`. You may need to enter BIOS and adjust the boot settings to boot to the Linux bootloader.

#### Alternative using old style disk partitioning

Instead of the "Partition and format the boot drive" above, do this:

```
# partition and format the boot disk in old school fashion, use the appropriate device name throughout
fdisk /dev/sda
# n
# (press enter several times)
# w
mkfs.ext4 /dev/sda1
mount /dev/sda1 /mnt
```

Instead of "Create book configuration" above, do this:

```
pacman -S grub os-prober
grub-install --recheck /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
```

## Configuring Arch Linux

1. Login as `root`.

```
pacman -S pkgfile
pkgfile --update    (pkgfile is useful to find out what packages contains a command file)
pacman -S vim       (installs vim, also ruby, python2, and lua)
ln -s /usr/bin/python2 /usr/bin/python   (makes the "python" command use Python 2. We don't need no stinking Python 3.)
useradd -m -G wheel -s /bin/bash admin       (adds user admin, pick your own username if you want)
passwd admin
(enter password for admin user)
EDITOR=vim visudo
(uncomment the line "# %wheel ALL=(ALL) NOPASSWD: ALL")
```

## Configuring the network

As root:

```
systemctl enable systemd-networkd
systemctl start systemd-networkd
systemctl enable systemd-resolved
systemctl start systemd-resolved
ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
```

### Recycling DHCP lease after setting fixed IP address on DHCP server

As root:

```
rm /var/lib/dhcpcd/dhcpcd-<link-name>.lease
systemctl reboot
```

## Setting up SSH access

As root:

```
pacman -S openssh
systemctl enable sshd
systemctl start sshd
```

As user `admin`:  `mkdir ~/.ssh`

Now go to another machine: (can be OS X or Linux)

```
ssh-keygen -f ~/.ssh/utility -N ""       (or whatever finename you wish besides "utility")
scp ~/.ssh/utility.pub admin@<ip-address>:.ssh/authorized_keys
```

You can now login to the utility machine by running `ssh -i ~/.ssh/utility admin@<ip-address>`.

Now lock down SSH on the machine by disabling root access, and password login:

```
sudo vim /etc/ssh/sshd_config
# uncomment line #PasswordAuthentication and change "yes" to "no"
# uncomment line #AllowAgentForwarding yes
# uncomment line #PermitRootLogin and change parameter to "no"
sudo systemctl restart sshd
```

### Setting up a second adapter with a static IP

As root, create a network unit called `internal.network` like this in `/etc/systemd/network`:
(use the correct device name)

```
[Match]
Name=enp2s0
[Network]
Address=10.0.0.1/16
```

Then, `systemctl restart systemd-networkd` to enable it.

## Mounting additional disks at boot

As root, put a mount unit like this into `/etc/systemd/system`, and call it `disk1.mount`.
Then `systemctl enable disk1.mount` and `systemctl start disk1.mount`.

```
[Unit]
Description=Mount Disk 1
Before=local-fs.target umount.target
Conflicts=umount.target
DefaultDependencies=no
[Mount]
What=/dev/sdb1
Where=/disk1
[Install]
WantedBy=local-fs.target
```

## Setting up Wake On LAN for your utility machine

[See here for advice]() on enabling Wake On Lan on the utility machine. I had to enable "PCIE Devices Power On" in one of the BIOS menus.

Then, `brew install wakeonlan` on your Mac. Find the adapter MAC address from `ip addr`, and save it on your Mac. 

`wakeonlan <MAC address>` will then power up your machine from anywhere on the LAN.

## Updating your utility machine

`sudo pacman -Syu` will update all packages on your machine. You will need to reboot if the Linux kernel is updated.