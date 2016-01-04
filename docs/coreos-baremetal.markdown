# How to PXE boot CoreOS from an OS X server

This guide uses two excellent projects: [pixiecore](https://github.com/danderson/pixiecore) and [coreos-baremetal](https://github.com/coreos/coreos-baremetal). Both of these projects are written in Go, and can be built for either Linux or OS X. This guide details how to install and use them to set up a fast, flexible PXE boot environment on OS X.

It is possible to use older projects like [dnsmasq](http://www.thekelleys.org.uk/dnsmasq/doc.html) to accomplish this goal, but setup is much more complex and less flexible.

## Initial setup

## Prerequisites

### Machines

You will need an OS X machine and servers for PXE booting CoreOS. You will need administrative access to the OS X machine.
All these machines should have Ethernet wired connections to the local network.

### Local network

Your local network should have wired Ethernet connections available for your OS X machine and your servers.
The network must have Internet access, typically via a NAT router.
The network should have a DHCP service, and you need administrative access to the DHCP server.
In many cases, this is simply your network's NAT router.

You will need to assign static IP addresses to the OS X machine and the servers. So create an IP addressing plan for this.

The best way to do this (and what is assumed here) is to have a DHCP server that supports DHCP reservations (aka static DHCP), which allows you to assign a fixed IP address to a machine's MAC address.
When a machine boots, it will ask the DHCP server for an IP address, but will always get the reserved static IP address.

Configure the DHCP server to assign a static IP to your OS X machine, then reboot the machine (or refresh the DHCP lease).

### Servers to PXE boot CoreOS

These servers should be Ethernet connected to your network, and be capable of PXE booting over the network.
Most network adapters support PXE boot, and typically new servers come with PXE boot already set up.
You may need to boot your server into its BIOS and reconfigure its boot settings to do this.

### OS X setup

The OS X machine must have the Go language installed and its environment set up.
Recommend using [Homebrew](http://brew.sh) and `brew install go`. Then [follow instructions](https://golang.org/doc/install#testing) to set up your Go project directory and test your installation.

### Download and build projects

```bash
go get github.com/coreos/coreos-baremetal
# (you will see an error message about no buildable code, ignore it)
cd $GOPATH/github.com/coreos/coreos-baremetal
./build darwin
go get github.com/danderson/pixiecore
```

## Create your PXE boot environment

### Create config directory

Create a directory for holding your PXE configurations and CoreOS images, and set the environment variable CBM to its path. (CBM stands for CoreOS Bare Metal.) Then:

```bash
cd $CBM
mkdir -p {data/cloud,data/machines/default,data/specs}
ln -s $GOPATH/github.com/coreos/coreos-baremetal/bin/server bootcfg
ln -s $GOPATH/github.com/bin/pixiecore pixiecore
```

```bash
# (the following downloads a version of CoreOS. Modify "alpha" and "current" to the channel and release that you wish to use.)
$GOPATH/github.com/coreos/coreos-baremetal/scripts/get-coreos alpha current
```

### Create SSH keypair

Create an SSH keypair for your PXE boot servers using `ssh-keygen`. In this example we'll call it `coreos-pxe`.

### Create default cloud config file

Create `$CBM/cloud/pxe-ignition-default.json` adding your SSH public key file contents:

```json
{
  "ignitionVersion": 1,
  "passwd": {
    "users": [
      {
        "name": "core",
        "sshAuthorizedKeys": [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDXmYK4l3mXfIrSmV3IMZK/BC8CKPeZ/7VDkM1x8V5ulFZLM9gKhd//eGP10gvkoinOLYBFUntDZA4v6BB5UPI1sr2AaJ0LsHoMpebnMW4oNgx/8aBIChujhYmeAQut+pc9k24MYkFq2TJLCl0pE3S6Hxgw6oJUW0DyNWlSSBLcu/neiZO3Lw2uVScPlBQkxvhJa0SprqTgXJhht2QXrag/QAQzaHKtim7ZOC96qITrYy+04JqtWZ2BTAaGyQiAjzroDBMZm21RbC0sB2Q7E7RanjKEfw45zBvM7/G5g/QllNrWJFIhcSr5oMslTirlxUS1AGcf194KVZh+uJcxct6x spebrown@SpencerMBPro"
        ]
      }
    ]
  },
  "systemd": {
    "units": [
      {
        "name": "set-hostname.service",
        "enable": true,
        "contents": "[Unit]\n[Service]\nType=oneshot\nExecStart=/usr/bin/hostnamectl set-hostname default-host\n[Install]\nWantedBy=multi-user.target"
      }
    ]
  }
}
```
### Create default machine entry

Create `$CBM/machines/default/machine.json` as follows: (if you downloaded a specific CoreOS version, substitute that version number for `current`)

```json
{
    "id": "default",
    "spec": {
      "boot": {
          "kernel": "/images/coreos/current/coreos_production_pxe.vmlinuz",
          "initrd": ["/images/coreos/current/coreos_production_pxe_image.cpio.gz"],
          "cmdline": {
              "coreos.config.url": "http://10.2.0.200:8080/cloud?uuid=default",
              "coreos.autologin": "",
              "coreos.first_boot": "1"
          }
      },
      "cloud_id": "pxe-ignition.json"
    },
    "spec_id": ""
}
```

## First boot of PXE server

On your OS X machine, start pixiecore by opening a terminal window and:

```bash
cd $CBM
./sudo ./pixiecore -api=http://localhost:8080/pixiecore
```

pixiecore must run as root because it opens privileged ports to listen for DHCP and TFTP requests from the PXE booted servers.
You must enter your OS X password.

Start the coreos-baremetal server by opening another terminal window and:

```bash
cd $CBM
./bootcfg
```

Now, power on your PXE boot server. For first time use, you may want to attach a keyboard and display for debugging purposes.
You should see CoreOS boot up. If you have a keyboard/display attached, CoreOS will automatically login the core user.

### Troubleshooting

The most common cause of PXE boot failure is incorrect BIOS configuration on the booted server.

### Note the server MAC address

The window running `pixiecore` will have a message similar to:

`2016/01/04 07:05:21 [ProxyDHCP] Offering to boot 90:2b:34:14:f6:6a (via 10.2.0.200)`

Make a note of the MAC address of your server, in this example it is `90:2b:34:14:f6:6a`

### Set server DHCP reserved IP address

On your DHCP service, use the MAC address noted above to set up a static reserved IP for the server.
Reboot the server so that it picks up the reserved IP.

### SSH into server

Use your private SSH key to login remotely to the server, using the static IP address you assigned.
The username is `core`. For example:

`ssh -i ~/.ssh/my-pxe-key core@10.2.0.197`

