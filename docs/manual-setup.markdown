# How to network boot CoreOS machines from an OS X or CoreOS server

NOTE: this guide is for manual setup. The current project has automation of the setup using Ansible. See `README.md`.

This guide uses two excellent projects: [dnsmasq](http://www.thekelleys.org.uk/dnsmasq/doc.html) and [coreos-baremetal](https://github.com/coreos/coreos-baremetal). Both of these work on either Linux or OS X. 
This guide details how to install and use them to set up a fast, flexible network boot environment on OS X.

It is possible to use older projects like [dnsmasq](http://www.thekelleys.org.uk/dnsmasq/doc.html) to accomplish this goal, but setup is much more complex and less flexible.

## Create your PXE boot environment

### Create the config directory

```bash
cd ~
mkdir cbm
export CBM=~/cbm
cd $CBM
mkdir -p {data/ignition,data/cloud,data/specs/first-time}
mkdir -p dnsmasq.data/tftp
ln -s $GOPATH/src/github.com/coreos/coreos-baremetal/bin/bootcfg bootcfg
ln -s $GOPATH/src/github.com/coreos/coreos-baremetal/scripts/get-coreos get-coreos
ln -s /usr/local/sbin/dnsmasq dnsmasq
```

### Download the CoreOS PXE binaries
The following downloads a version of CoreOS for PXE booting.
Modify "alpha" and "current" to the channel and release that you wish to use.

```bash
./get-coreos alpha current
```

### Create the SSH keypair

Create an SSH keypair for your PXE boot servers using `ssh-keygen`. In this example we'll call it `coreos-pxe`.

```bash
cd ~/.ssh
ssh-keygen -f coreos-pxe
# hit enter to take all defaults
```

### Create the first-time ignition config file

Create `$CBM/data/ignition/first-time.json` adding your SSH public key file contents:

```json
{
  "ignitionVersion": 1,
  "passwd": {
    "users": [
      {
        "name": "core",
        "sshAuthorizedKeys": [
          "PASTE YOUR SSH PUBLIC KEY HERE: CONTENTS OF FILE coreos-pxe.pub"
        ]
      }
    ]
  },
  "systemd": {
    "units": [
      {
        "name": "set-hostname.service",
        "enable": true,
        "contents": "[Unit]\n[Service]\nType=oneshot\nExecStart=/usr/bin/hostnamectl set-hostname first-time\n[Install]\nWantedBy=multi-user.target"
      }
    ]
  }
}
```
### Create the first-time spec

Create `$CBM/data/spec/first-time/spec.json` as follows:

* substitute the boot server's IP address for `10.2.0.200`
* if you downloaded a specific CoreOS version, substitute that version number for `current`

```json
{
  "id": "first-time",
  "boot": {
    "kernel": "/images/coreos/current/coreos_production_pxe.vmlinuz",
    "initrd": [
      "/images/coreos/current/coreos_production_pxe_image.cpio.gz"
    ],
    "cmdline": {
      "coreos.config.url": "http://10.2.0.200:8080/ignition?uuid=default",
      "coreos.autologin": "",
      "coreos.first_boot": "1"
    }
  },
  "ignition_id": "pxe-ignition-default.json"
}
```

### Create the dnsmasq config files

FOr OS X, create `$CBM/dnsmasq.data/dnsmasq.conf` as follows: (substitute your OS X username for `spencer`

```
# Disable DNS service
port=0

# Set the username that dnsmasq will switch to after startup
# note that dnsmasq must be started as root
user=spencer

# with no interface=, dnsmasq on OS X binds to UDP ports as follows:
#   67 (DHCP) on *
#   69 (TFTP) on adapter's IP e.g. 10.2.0.200 and also 127.0.0.1
#   4011 (PXE proxyDHCP) on *
#   also a bunch of IPv6 listent
#interface=en0

# with listen-address, dnsmasq on OS X binds to UDP ports as follows:
listen-address=10.2.0.200
#   67 (DHCP) on *
#   69 (TFTP) on listen-address IP
#   4011 (PXE proxyDHCP) on *

# bind-interfaces disallows binding to 0.0.0.0, because dnsmasq doesn't support that on OS X
# this avoids a warning in the log
bind-interfaces

# Make DHCP run in proxy mode, it does not supply IP addresses, only PXE responses
dhcp-range=10.2.0.0,proxy

# Relocate the dnsmasq.leases file which is created but not used
dhcp-leasefile=/Users/spencer/pixie/dnsmasq.data/dnsmasq.leases

# Enable the TFTP server
enable-tftp
tftp-root=/Users/spencer/pixie/dnsmasq.data/tftp

# kill multicast for DHCP PXE
dhcp-option=vendor:PXEClient,6,2b

# set tag "ipxe" if request comes from iPXE ("iPXE" user class)
dhcp-userclass=set:ipxe,iPXE

# if PXE request came from regular PXE firmware, serve iPXE firmware (via TFTP)
dhcp-boot=tag:!ipxe,undionly.kpxe
pxe-service=tag:!ipxe,x86PC,"PXE chainload to iPXE",undionly.kpxe

# if PXE request came from iPXE, grab an iPXE boot script from the bootcfg server
dhcp-boot=tag:ipxe,http://10.2.0.200:8080/boot.ipxe
pxe-service=tag:ipxe,x86PC,"Run iPXE boot",http://10.2.0.200:8080/boot.ipxe
```

## Set up for subsequent boots of booted machine

### Set DHCP reserved IP address for machine

On your DHCP service, use the MAC address noted above to set up a static reserved IP for the machine.

### Set up configuration for the machine

Create a directory for this machine, named with the MAC address:

```bash
# Obviously, substitute the correct MAC address #
mkdir $CBM/data/90:2b:34:14:f6:6a
```

Inside this directory, create a `machine.json` file for that machine:

### Reboot the machine

It should boot up with the reserved IP address, and the new PXE boot configuration.

### SSH into server

Use your private SSH key to login remotely to the server, using the static IP address you assigned.
The username is `core`.

`ssh -i ~/.ssh/coreos-pxe core@10.2.0.197`

### Clean out disks

```bash
sudo gdisk /dev/sda
# use "o" to completely wipe the disk
# use "n" to create a new partition
```

# Notes

CoreOS PXE boot with kernel parameter `root=/dev/sda1` to an empty disk sets it up as follows:

Populated directories:

```
/etc
/var
```

Directories that exist, but are mounted with `tmpfs` file systems:

```
/run
/media
/tmp
```

`/usr` is a special case. It is mounted as a squashfs file system pointing to `usr.squashfs`. So it runs out of memory, I guess. 
`/dev/loop0` is mounted on `/usr` by the `usr.mount` service.