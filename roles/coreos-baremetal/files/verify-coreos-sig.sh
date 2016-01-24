#!/usr/bin/env bash

gpg --import < "$1/CoreOS_Image_Signing_Key.asc"
echo "Adding trust for CoreOS signing key:"
echo "04127D0BFABEC8871FFB2CCE50E0885593D2DCB4:6:" | gpg --import-ownertrust
gpg --verify "$1/coreos_production_pxe.vmlinuz.sig"
gpg --verify "$1/coreos_production_pxe_image.cpio.gz.sig"
