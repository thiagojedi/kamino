# Upstream
FROM ghcr.io/get-aurora-dev/common:latest AS aurora-common
FROM ghcr.io/ublue-os/brew:latest as brew
FROM ghcr.io/ublue-os/akmods-nvidia-lts:main-43 as nvidia

# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY --from=nvidia / /nvidia

COPY --from=aurora-common /logos /system_files/shared
COPY --from=aurora-common /system_files /system_files
COPY --from=aurora-common /wallpapers /system_files/shared

COPY --from=brew /system_files /system_files/shared

COPY system_files /system_files/shared

COPY build_files /

# Base Image
FROM ghcr.io/ublue-os/kinoite-main:latest

ARG VERSION=local

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/10-packages.sh && \
    /ctx/20-image-info.sh && \
    /ctx/30-nvidia.sh && \
    /ctx/40-services.sh

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
