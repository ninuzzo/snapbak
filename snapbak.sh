#!/bin/bash
# Back up the host configuration and LVM-based virtual machines,
# by rsyncing on an external diskdrive.
#
# Antonio Bonifati <antonio.bonifati@gmail.com>

# Source the config file, first of all.
CONF=/usr/local/etc/snapbak.conf
source $CONF || exit

# Make sure the USB disk is mounted!
grep -q "$BAKMNT" /proc/mounts || mount "$BAKMNT" || exit

# Optional selective host configuration backup.
[ "$(type -t backup_host_config)" = "function" ] && backup_host_config

# Snapshots a VM and mounts the snapshot readonly (e.g. for backup purposes).
# $1 - vm name
# Creates global variables SNAPNAME and SNAPVOL
create_snapshot() {
  # Tries to make up a unique snapshot name for a VM.
  SNAPNAME="$1snap$(date +%s)"

  SNAPVOL="/dev/$VG/$SNAPNAME"

  local lvpath="$VG"/"$1" \
    # Compute the snapshot LV size in megabytes (m) as a percentage of the VM virtual disk size.
    lvsize=$(echo "$(lvs --noheadings --units m -o lv_size "$lvpath" | sed 's/m$//') * $SNAPSIZE / 100" | bc -l)

  lvcreate -s -n "$SNAPNAME" -L ${lvsize}m "$lvpath" >/dev/null &&

  # Expose the partitions within the snapshot.
  kpartx -a "$SNAPVOL" &&

  # Assume the first partition is the one to backup.
  mount -t auto -o ro "/dev/mapper/$VG-${SNAPNAME}p1" "$SNAPMNT"
}

# Unmount and destroy the last created VM snapshot.
destroy_snapshot() {
  umount "$SNAPMNT" &&
  kpartx -d "$SNAPVOL" &&
  lvremove -f "$SNAPVOL" >/dev/null
}

# Update a VM backup.
# $1 - vm name
update_backup() {
  local destdir="$BAKMNT/$1/"

  # Make sure the destination dir exists
  mkdir -p "$destdir" &&

  rsync -aq --delete "$SNAPMNT/" "$BAKMNT/$1/"
}

# Create a temporary mount point to use for snapshots.
SNAPMNT=$(mktemp -d)

# Online VM backup, using LVM snapshots.
for vm in "${VMS[@]}"; do
  create_snapshot "$vm" && {
    update_backup "$vm"
    destroy_snapshot "$vm"
  }
done

rmdir $SNAPMNT

# Unmount the disk, just in case someone pulls it out.
umount "$BAKMNT"
