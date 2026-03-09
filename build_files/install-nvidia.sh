#!/bin/bash

export AKMODNV_PATH=/ctx/nvidia/rpms
export IMAGE_NAME=kinoite

# Remove nvidia conflicting packages
dnf5 -y remove \
	nvidia-gpu-firmware \
	rocm-hip \
	rocm-opencl \
	rocm-clinfo \
	rocm-smi

# Run ublue-os script
/ctx/nvidia/rpms/ublue-os/nvidia-install.sh

# Prepare boot
rm -f /usr/share/vulkan/icd.d/nouveau_icd.*.json
ln -sf libnvidia-ml.so.1 /usr/lib64/libnvidia-ml.so
tee /usr/lib/bootc/kargs.d/00-nvidia.toml <<EOF
kargs = ["rd.driver.blacklist=nouveau", "modprobe.blacklist=nouveau", "nvidia-drm.modeset=1", "initcall_blacklist=simpledrm_platform_driver_init"]
EOF
