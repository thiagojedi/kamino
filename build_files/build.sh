#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1

#region Install nvidia drivers

echo  "WAT"

dnf5 -y remove \
    nvidia-gpu-firmware \
    rocm-hip \
    rocm-opencl \
    rocm-clinfo \
    rocm-smi

dnf5 -y copr enable ublue-os/staging

dnf5 -y install \
        egl-wayland.x86_64 \
        egl-wayland.i686

echo "disabling negativo17-fedora-multimedia to ensure negativo17-fedora-nvidia-580 is used"
dnf5 config-manager setopt fedora-multimedia.enabled=0

dnf5 config-manager addrepo --from-repofile=https://negativo17.org/repos/fedora-nvidia-580.repo

dnf5 -y install \
    nvidia-driver \
    nvidia-driver-libs

# re-enable negativo17-mutlimedia since we disabled it
dnf5 config-manager setopt fedora-multimedia.enabled=1

#endregion

#### Example for enabling a System Unit File

# systemctl enable podman.socket

# Copy system files
# rsync -rvK /ctx/system_files/desktop/ /