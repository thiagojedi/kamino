FROM ghcr.io/get-aurora-dev/common:latest AS aurora-common
FROM ghcr.io/ublue-os/brew:latest as brew
# Nvidia drivers from bazzite
# FROM ghcr.io/bazzite-org/kernel-bazzite:latest-f43-x86_64 AS kernel
# FROM ghcr.io/bazzite-org/nvidia-drivers:580.95.05-f43-x86_64 as nvidia
FROM ghcr.io/ublue-os/akmods-nvidia-lts:main-43 as nvidia

# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx

COPY --from=nvidia / /nvidia

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
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    find /ctx/nvidia && \
    dnf5 -y install nvidia-kmod-common
    dnf5 -y install /ctx/nvidia/rpms/ublue-os/ublue-os-nvidia*.rpm && \
    dnf5 -y install /ctx/nvidia/rpms/kmods/kmod-nvidia*.rpm

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
