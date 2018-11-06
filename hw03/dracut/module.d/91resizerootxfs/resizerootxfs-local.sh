#!/bin/sh
resize_local()
{
mkdir /mnt
lvm lvcreate --config 'global {locking_type=1}' -n temp_xfs -L 8G vg0
mkfs.xfs -f /dev/vg0/temp_xfs
mount /dev/vg0/temp_xfs /tmp
mount /dev/vg0/lvm_root /mnt
xfsdump -J - /mnt | xfsrestore -J - /tmp
umount /tmp
umount /mnt
lvm lvreduce --config 'global {locking_type=1}' --yes -f -L -12G /dev/vg0/lvm_root
mkfs.xfs -f -m uuid=1b615c91-2ba1-4877-a06d-fa5d14844aac /dev/vg0/lvm_root
mount /dev/vg0/temp_xfs /tmp
mount /dev/vg0/lvm_root /mnt
xfsdump -J - /tmp | xfsrestore -J - /mnt
umount /tmp
umount /mnt
lvm lvremove --config 'global {locking_type=1}' --yes -f /dev/vg0/temp_xfs
}
resize_local
