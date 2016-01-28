#!/usr/bin/env bash

if [ -e get-pip.py ]
then
    echo "Already set up for Ansible"
    exit
fi

wget https://bitbucket.org/squeaky/portable-pypy/downloads/pypy-4.0.1-linux_x86_64-portable.tar.bz2
tar -jxf pypy-4.0.1-linux_x86_64-portable.tar.bz2
rm pypy-4.0.1-linux_x86_64-portable.tar.bz2
mv pypy-4.0.1-linux_x86_64-portable pypy
ln -s pypy/bin/pypy python
curl -O https://bootstrap.pypa.io/get-pip.py
# ./python get-pip.py