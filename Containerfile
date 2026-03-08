FROM ghcr.io/get-aurora-dev/common:latest AS aurora-common
FROM ghcr.io/ublue-os/brew:latest as brew
# Nvidia drivers from bazzite
FROM ghcr.io/bazzite-org/kernel-bazzite:latest-f43-x86_64 AS kernel
FROM ghcr.io/bazzite-org/nvidia-drivers:580.95.05-f43-x86_64 as nvidia

# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /

# # /* https://github.com/get-aurora-dev/common */
# COPY --from=aurora-common /logos /system_files/shared
# COPY --from=aurora-common /system_files /system_files
# COPY --from=aurora-common /wallpapers /system_files/shared

# # /* https://github.com/ublue-os/brew */
# COPY --from=brew /system_files /system_files/shared

COPY system_files /system_files/

# Base Image
FROM ghcr.io/ublue-os/kinoite-main:latest

### MODIFICATIONS
## make modifications desired in your image and install packages by modifying the build.sh script
## the following RUN directive does all the things required to run "build.sh" as recommended.

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh

### Install BREW
COPY --from=brew /system_files /
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /usr/bin/systemctl preset brew-setup.service && \
    /usr/bin/systemctl preset brew-update.timer && \
    /usr/bin/systemctl preset brew-upgrade.timer

### Install NVIDIA driver
## this is the same script used by Bazzite

RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=kernel,src=/,dst=/rpms/kernel \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/install-kernel && \
    # dnf5 -y config-manager setopt "*rpmfusion*".enabled=0 && \
    rm -rf /.git && \
    /ctx/cleanup

# Remove everything that doesn't work well with NVIDIA, unset skip_if_unavailable option if was set beforehand
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    dnf5 config-manager unsetopt skip_if_unavailable && \
    dnf5 -y remove \
        nvidia-gpu-firmware \
        rocm-hip \
        rocm-opencl \
        rocm-clinfo \
        rocm-smi && \
    /ctx/cleanup

RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    --mount=type=secret,id=GITHUB_TOKEN \
    --mount=type=bind,from=nvidia,src=/,dst=/rpms/nvidia \
    dnf5 -y copr enable ublue-os/staging && \
    dnf5 -y install \
        egl-wayland.x86_64 \
        egl-wayland.i686 && \
    /ctx/install-nvidia && \
    rm -f /usr/share/vulkan/icd.d/nouveau_icd.*.json && \
    ln -s libnvidia-ml.so.1 /usr/lib64/libnvidia-ml.so && \
    dnf5 -y copr disable ublue-os/staging && \
    /ctx/cleanup

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
