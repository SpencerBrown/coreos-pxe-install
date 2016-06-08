# Setting up VirtualBox iPXE support

VirtualBox comes with virtual LAN Boot ROM that is a build of iPXE, with support for HTTP, but not for bzImage.
bxImage is required for CoreOS, because they ship their PXE boot initramfs in cpio.bz format.

So we have to build our own iPXE boot ROM and tell VirtualBox to do it.

## Setup

[See here](http://ipxe.org/download) [and here](https://git.ipxe.org/ipxe.git/blob/HEAD:/src/config/vbox/README) for source material

In short, get a Linux box, ensure you have:

* git
* gcc (version 3 or later)
* binutils (version 2.18 or later)
* make
* perl
* syslinux (for isolinux, only needed for building .iso images)
* liblzma or xz header files
* zlib, binutils and libiberty header files (only needed for EFI builds)

## Build

```bash
git clone git://git.ipxe.org/ipxe.git
cd ipxe/src
```

Edit `config/general.h` and uncomment this line:

`//#define      IMAGE_BZIMAGE           /* Linux bzImage image support */`

Then:
 
```bash
make CONFIG=vbox bin/virtio-net.isarom
```

## Install

```bash
vboxmanage setextradata global VBoxInternal/Devices/pcbios/0/Config/LanBootRom <absolute-path>/virtio-net.isarom
```

## Run

Define a VM whose NIC is of type `virtio-net` (other types won't work any more for PXE booting). 
Change its boot settings to allow network boot.
Set up your PXE server appropriately, and start the machine.