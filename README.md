# Status: DO NOT USE. In transition.

Work items: 

1. Stop using Ansible and start using Go language with templating instead.
2. Update due to lots of changes in the coreos-baremetal project.
3. Update because the iPXE driver for VirtualBox is now too large (see repo virtualbox-ipxe)


# Network booting CoreOS to bare metal machines

This project uses two excellent projects: [dnsmasq](http://www.thekelleys.org.uk/dnsmasq/doc.html) and [coreos-baremetal](https://github.com/coreos/coreos-baremetal). Both of these work on either Linux or OS X. 

This guide details how to set up an "environment", which is a cluster of CoreOS bare metal servers.
Ansible playbooks are provided to automate the setup and operation.

Testing have been done using OS X as the boot server, and VirtualBox virtual machines and real machines as the booted machines.

# Initial setup

See [Initial Setup document](docs/initial-setup.markdown).

# Create an environment

To create an environment, pick a name that's unique in your repository. For this example let's call it `vbox`.
The environment represents a CoreOS cluster of bare metal machines, which share an SSH key and a configuration.

`ansible-playbook -e env=vbox -i hosts make-environment.yaml` will create your environment for you, 
including a new SSH keypair `vbox-key` and `vbox-key.pub`. 
This keypair is saved in your `~/.ssh` directory, and also copied to your environment's `secret-files` and `public-files` directories.

Once your environment is set up, change to its directory, for example, `cd vbox`.

## Sharing an environment

If you wish to share your environment, configurations, and secrets with others, create a fork of the repo.
Do your setup, then encrypt your secrets and push the results to your fork on GitHub.
Another team member can clone your repo and add the environment's password, then decrypt the secrets.
See [Sharing Secrets](docs/sharing-secrets.markdown) for more information.

# Configure your environment

Change to your environment directory, and edit the file `group_vars/local/coreos.yaml`.
Set the variables according to your local configuration as follows:

Variable | Value | Default
---------|-------|--------
boot_server_ip | IP address of boot server | 10.2.0.200
boot_server_ip_base | Base IP address of local network | 10.2.0.0 |
boot_server_ip_netmask | Netmask for local network | 255.255.255.0
coreos_channel | CoreOS release channel (alpha, beta, stable) | alpha
coreos_release | CoreOS specific release e.g. 935.0.0 | current

Setting coreos_release to "current" will fetch the latest release for that release channel.

Then, run `ansible_playbook ../make_cbm.yaml` to configure your environment and download the necessary binaries.
If anything changes, rerun the playbook to reconfigure the environment.

# Start the boot services

Set the environment variable CBM to the path for the `cbm` directory for your environment. For example:

`export CBM=~/src/coreos-pxe-install/vbox/cbm`

## OS X

Start the coreos-baremetal service:

```bash
cd $CBM
./bootcfg --address=0.0.0.0:8080
```

In another terminal window, start the dnsmasq service:

```bash
cd $CBM
sudo ./dnsmasq -C dnsmasq.data/dnsmasq.conf -k --log-facility=- --log-dhcp
```

dnsmasq must run as root because it opens privileged ports to listen for DHCP and TFTP requests from the PXE booted servers.
You must enter your OS X password.

# Boot your booted machine for the first time

Power on the booted machine. For first time use, you may want to attach a keyboard and display for debugging purposes.
You should see CoreOS boot up with the hostname set to `default`.
If you have a keyboard/display attached, CoreOS will automatically login the core user.

SSH into the machine. Commands to use:
* `ip addr` - discover IP addresses and MAC addresses.
* `lsblk` - discover disks.

## Troubleshooting

The most common cause of network boot failure is incorrect BIOS configuration on the booted server.

## Note the server MAC address

The window running `dnsmasq` will have a message similar to:

`dnsmasq-dhcp[8655]: PXE(en0) 90:2b:34:14:f6:6a proxy`

Make a note of the MAC address of your booted machine, in this example it is `90:2b:34:14:f6:6a`


