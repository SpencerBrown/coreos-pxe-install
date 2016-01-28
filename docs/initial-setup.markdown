# Initial setup

## Machines

You will need an OS X or CoreOS machine to act as a PXE boot server.
You will need machines that you want to PXE boot into CoreOS. We will call these the booted machines.
You will need administrative access to the boot server.
You will need physical access, most likely, to the booted servers.
All these machines should have Ethernet wired connections to the local network.

## Local network

Your local network should have wired Ethernet connections available for your boot server and your booted machines.
The network must have Internet access, typically via a NAT router.
The network should have a DHCP service, and you need administrative access to the DHCP server.
In many cases, this is simply your network's NAT router.

You will need to assign static IP addresses to the boot server and the booted machines. So create an IP addressing plan for this.

The best way to do this (and what is assumed here) is to have a DHCP server that supports DHCP reservations (aka static DHCP), which allows you to assign a fixed IP address to a machine's MAC address.
When a machine boots, it will ask the DHCP server for an IP address, but will always get the reserved static IP address.

Configure the DHCP server to assign a static IP to your boot server, then reboot the machine or refresh the DHCP lease to get the new IP address.

## Booted machines

These machines should be Ethernet connected to your network, and be capable of PXE booting over the network.
Most network adapters support PXE boot, and typically new machines come with PXE boot already set up as a default boot.
You may need to boot a machine into its BIOS and reconfigure its boot settings for PXE booting.

In some cases, the Ethernet port on the motherboard does not support PXE booting.
The only recourse is to add a network adapter that does support PXE boot.

## Boot server setup

The boot server must have the Go language installed and its environment set up.
And also Python and Ansible.

### OS X

Recommend using [Homebrew](http://brew.sh)
 
`brew install go`. Then [follow instructions](https://golang.org/doc/install#testing) to set up your Go project directory and test your installation.
 
 `brew install python` and `pip install ansible`.
 
 `git clone https://github.com/SpencerBrown/coreos-pxe-install.git`. 
 Or you may wish to fork the repo so you have a place to push your environments and configurations and share them with others.

### CoreOS setup

You can install Go directly on CoreOS, no need to use containers. Logged in as user `core`:

```bash
# Substitute a newer version of Go for "1.5.3" as appropriate
wget https://storage.googleapis.com/golang/go1.5.3.linux-amd64.tar.gz
tar -xzf go1.5.3.linux-amd64.tar.gz
cp .bashrc bashrc
echo 'export GOROOT=~/go' >> bashrc
echo 'export PATH=$PATH$GOROOT/bin' >> bashrc
echo 'export GOPATH=$HOME/work' >> bashrc
rm .bashrc
mv bashrc .bashrc
source .bashrc
```

TODO: install PyPY and Ansible directly on CoreOS.

### Download and build projects

```bash
go get -d github.com/coreos/coreos-baremetal/cmd/bootcfg
cd $GOPATH/src/github.com/coreos/coreos-baremetal
./build
```

The binary `bootcfg` is built for your OS and saved in `$GOPATH/src/github.com/coreos/coreos-baremetal/bin`.

OS X: `brew install dnsmasq`

CoreOS: TBD