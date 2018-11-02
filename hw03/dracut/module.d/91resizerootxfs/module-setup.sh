#!/bin/bash

check() {
return 0
}

depends() {
return 0
}

install() {
     inst_hook pre-mount 00 "$moddir/resizerootxfs-local.sh"
}
