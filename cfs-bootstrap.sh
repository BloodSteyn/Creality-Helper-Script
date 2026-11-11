#!/bin/sh

# Installs the Helper Script on a K1 series printer running the CFS Upgrade Kit
# firmware (2.3.5.x), where the Git provided with the firmware is not able to
# clone GitHub repositories.
#
# Run it from an SSH session on the printer:
#
#   wget --no-check-certificate -O /tmp/cfs-bootstrap.sh https://raw.githubusercontent.com/BloodSteyn/Creality-Helper-Script/main/cfs-bootstrap.sh
#   sh /tmp/cfs-bootstrap.sh

set -e

HELPER_SCRIPT_URL="https://github.com/BloodSteyn/Creality-Helper-Script.git"
HELPER_SCRIPT_FOLDER="/usr/data/helper-script"
ENTWARE_INSTALLER_URL="http://bin.entware.net/mipselsf-k3.4/installer/generic.sh"

if [ "$(id -u)" != "0" ]; then
  echo "Error: This script must be run as root on the printer."
  exit 1
fi

if [ -d "$HELPER_SCRIPT_FOLDER" ]; then
  echo "Error: $HELPER_SCRIPT_FOLDER already exists, Helper Script is already installed."
  exit 1
fi

if [ ! -f /opt/bin/opkg ]; then
  echo "Info: Installing Entware..."
  wget "$ENTWARE_INSTALLER_URL" -O /tmp/entware-generic.sh
  sh /tmp/entware-generic.sh
  rm -f /tmp/entware-generic.sh
  if ! grep -q "rc.unslung" /etc/rc.local 2>/dev/null; then
    echo "Info: Starting Entware services at boot..."
    if [ -f /etc/rc.local ]; then
      sed -i '/^exit 0/d' /etc/rc.local
    fi
    echo '/opt/etc/init.d/rc.unslung start' >> /etc/rc.local
    echo 'exit 0' >> /etc/rc.local
  fi
fi

export PATH=/opt/bin:/opt/sbin:$PATH

echo "Info: Installing Git from Entware..."
opkg update
opkg install ca-bundle git git-http

if [ ! -f /opt/bin/git ]; then
  echo "Error: Git installation failed."
  exit 1
fi

if [ -e /usr/bin/git ] && [ ! -L /usr/bin/git ] && [ ! -e /usr/bin/git.bak ]; then
  mv /usr/bin/git /usr/bin/git.bak
fi
ln -sf /opt/bin/git /usr/bin/git

echo "Info: Downloading Helper Script..."
git clone --depth 1 "$HELPER_SCRIPT_URL" "$HELPER_SCRIPT_FOLDER"

echo
echo "Helper Script has been installed. Run it with:"
echo
echo "  sh $HELPER_SCRIPT_FOLDER/helper.sh"
echo
