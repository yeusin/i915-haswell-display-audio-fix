#!/usr/bin/env bash
set -euo pipefail

# Ensure running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo: sudo ./install-patched-driver.sh"
    exit 1
fi

KVER=$(uname -r)
MOD_DIR="/lib/modules/${KVER}/kernel/sound/hda/controllers"
TARGET="${MOD_DIR}/snd-hda-intel.ko.zst"
BACKUP="${MOD_DIR}/snd-hda-intel.ko.zst.stock-backup"
PATCHED_ZST="$(dirname "$0")/snd-hda-intel.ko.zst"

if [ ! -f "$PATCHED_ZST" ]; then
    echo "Error: $PATCHED_ZST not found. Run make first."
    exit 1
fi

echo "==> Backing up stock module..."
if [ ! -f "$BACKUP" ]; then
    cp -v "$TARGET" "$BACKUP"
else
    echo "Backup already exists at $BACKUP"
fi

echo "==> Installing patched module..."
cp -v "$PATCHED_ZST" "$TARGET"

echo "==> Updating module dependencies..."
depmod -a "$KVER"

echo "==> Reloading audio driver (stopping audio services temporarily)..."
# Stop pipewire/wireplumber for logged in users
pkill -u 1000 -f "pipewire|wireplumber" || true
sleep 1

# Reload snd_hda_intel
modprobe -r snd_hda_intel || true
sleep 1
modprobe snd_hda_intel

echo "==> Verifying module loading..."
dmesg | tail -n 15

echo ""
echo "Patch applied and driver reloaded successfully!"
