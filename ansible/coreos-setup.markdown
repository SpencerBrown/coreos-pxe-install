# Setting up CoreOS for Ansible

Almost all Ansible operations on remote servers require Python 2.
CoreOS does not have Python, nor does it have a package manager to install Python.
So we need to install Python by direct means.

[An earlier project](https://github.com/defunctzombie/ansible-coreos-bootstrap) recommended using [PyPy](http://pypy.org) Python due to its lightweight nature and small set of dependencies on the operating system.

This document shows a simplified method for installing PyPy on CoreOS, suitable for Ansible work.

## Download and install PyPy Portable version on CoreOS

Login to the CoreOS machine as user `core`, and:

```bash
wget https://bitbucket.org/squeaky/portable-pypy/downloads/pypy-4.0.1-linux_x86_64-portable.tar.bz2
tar -jxf pypy-4.0.1-linux_x86_64-portable.tar.bz2
rm pypy-4.0.1-linux_x86_64-portable.tar.bz2
mv pypy-4.0.1-linux_x86_64-portable pypy
ln -s pypy/bin/pypy python
curl -O https://bootstrap.pypa.io/get-pip.py
./python get-pip.py
```
## Specify the Python interpreter for Ansible

Something like this in your inventory file:

```
[coreos]
10.2.0.197

[coreos:vars]
ansible_ssh_user=core
ansible_python_interpreter=/home/core/python
```

Put the machines running CoreOS in the `coreos` group. They will all have the variables in the `[coreos:vars]` section.
Ansible will then ssh to the machine as user `core`, and will find the PyPy version of Python in the proper place.