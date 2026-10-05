#!/usr/bin/env bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo: sudo ./restore-stock-driver.sh"
    exit 1
fi

KVER=$(uname -r)
MOD_DIR="/lib/modules/${KVER}/kernel/sound/hda/controllers"
TARGET="${MOD_DIR}/snd-hda-intel.ko.zst"
BACKUP="${MOD_DIR}/snd-hda-intel.ko.zst.stock-backup"

if [ ! -f "$BACKUP" ]; then
    echo "Error: Backup file $BACKUP does not exist!"
    exit 1
fi

echo "==> Restoring stock module from backup..."
cp -v "$BACKUP" "$TARGET"
rm -f "$BACKUP"

echo "==> Updating module dependencies..."
depmod -a "$KVER"

echo "==> Reloading stock audio driver..."
pkill -u 1000 -f "pipewire|wireplumber" || true
sleep 1
modprobe -r snd_hda_intel || true
sleep 1
modprobe snd_hda_intel

echo "Stock driver restored successfully."
