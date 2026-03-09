#!/bin/bash

set -ouex pipefail

### Install packages

# Remove nvidia conflicting files
dnf5 -y remove \
    nvidia-gpu-firmware \
    rocm-hip \
    rocm-opencl \
    rocm-clinfo \
    rocm-smi

AKMODNV_PATH=/ctx/nvidia/rpms IMAGE_NAME=kinoite /ctx/nvidia/rpms/ublue-os/nvidia-install.sh

rm -f /usr/share/vulkan/icd.d/nouveau_icd.*.json
ln -sf libnvidia-ml.so.1 /usr/lib64/libnvidia-ml.so
tee /usr/lib/bootc/kargs.d/00-nvidia.toml <<EOF
kargs = ["rd.driver.blacklist=nouveau", "modprobe.blacklist=nouveau", "nvidia-drm.modeset=1", "initcall_blacklist=simpledrm_platform_driver_init"]
EOF

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1

# dnf5 -y install tmux

#### Example for enabling a System Unit File

# systemctl enable podman.socket

# Copy system files
rsync -rvKl /ctx/system_files/shared/ /
