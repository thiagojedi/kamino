#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1

dnf5 versionlock add "qt6-*"
dnf5 versionlock add plasma-desktop

dnf5 -y copr enable ublue-os/staging
dnf5 -y install \
	fw-fanctrl
dnf5 -y copr disable ublue-os/staging

dnf5 -y copr enable ublue-os/packages
dnf5 -y install \
	krunner-bazaar \
	uupd
dnf5 -y copr disable ublue-os/packages

dnf5 -y install \
	alsa-firmware \
	fastfetch \
	fish \
	flatpak-spawn \
	gcc \
	git-credential-libsecret \
	glow \
	gum \
	lshw \
	nvtop \
	pam-u2f \
	pam_yubico \
	pamu2fcfg \
	plasma-wallpapers-dynamic \
	ptyxis \
	vim \
	ffmpeg \
	ffmpeg-libs \
	intel-vaapi-driver \
	libfdk-aac \
	libva-utils \
	pipewire-libs-extra \
	uld

# TODO: remove me on next flatpak release when preinstall landed in Fedora
dnf5 -y copr enable ublue-os/flatpak-test
dnf5 -y copr disable ublue-os/flatpak-test
dnf5 -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test swap flatpak flatpak
dnf5 -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test swap flatpak-libs flatpak-libs
dnf5 -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test swap flatpak-session-helper flatpak-session-helper
dnf5 -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test install flatpak-debuginfo flatpak-libs-debuginfo flatpak-session-helper-debuginfo

# Copy system files
rsync -rvKl /ctx/system_files/shared/ /

# Install flatpaks on system install
systemctl enable flatpak-preinstall.service

# Setup Homebrew
systemctl preset brew-setup.service
systemctl preset brew-update.timer
systemctl preset brew-upgrade.timer

# Fixes from ublue
systemctl enable ublue-system-setup.service
systemctl --global enable ublue-user-setup.service

/ctx/install-nvidia.sh
