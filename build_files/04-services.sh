# Install flatpaks on system install
systemctl enable flatpak-preinstall.service

# Setup Homebrew
systemctl preset brew-setup.service
systemctl preset brew-update.timer
systemctl preset brew-upgrade.timer

# Fixes from ublue
systemctl enable ublue-system-setup.service
systemctl --global enable ublue-user-setup.service

# This was disabled on aurora for some reason
systemctl --global disable bazaar.service