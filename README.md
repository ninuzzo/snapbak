snapbak
=======

LVM-based virtual machines backup with rsync

What it is
-------

It is a companion to [my selective backup kit - bak](http://ninuzzo.freehostia.com/sw/bak.html),
see -  for those who have LVM-based KVM virtual machines and want to back them
up using rsync (e.g. to an external cheap USB disk).

`snapbak.sh` can call `bak` to backup the host configuration and copy it to the
external drive, but that is optional. If you want to use `bak`, just uncomment
and edit the `backup_host_config` function in `backup.conf`.

Installation instruction
-------

Copy the configuration file into `/usr/local/etc/snapbak.conf` and the script
into `/usr/local/sbin/snapbak.sh` Edit the configuration file and change the
mount point `BAKMNT`, the list of VMs to backup from the default `(vm1 vm2)`
and set `VG` to the volume group the VMs are in. By default the latter is the
same as the short host name.

Depending on how much activity there is on you VMs during the backup, you may
want to adjust the size of snapshots. This is a percentage of each VM size as
set by `SNAPSIZE`, by default 10, which means 10%.

If you need other features to be implemented, please let me know. If you
implement a new feature by yourself, it would be nice if you contribute it.
