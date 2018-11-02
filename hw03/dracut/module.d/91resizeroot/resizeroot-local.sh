#!/bin/sh
resize_local()
{
lvm lvreduce --config 'global {locking_type=1}' -y -r -L -12G /dev/vg0/lvm_root
}
resize_local
