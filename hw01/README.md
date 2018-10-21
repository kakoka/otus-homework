`uname -a`

Linux localhost.localdomain 3.10.0-862.14.4.el7.x86_64 #1 SMP Wed Sep 26 15:12:11 UTC 2018 x86_64 x86_64 x86_64 GNU/Linux

`cat /etc/centos-release`

CentOS Linux release 7.5.1804 (Core) 

`cat /etc/centos-release`

Скачиваем ядро kernel.org

`cd /usr/src/kernels/
wget https://git.kernel.org/torvalds/t/linux-4.19-rc8.tar.gz
tar -zxvf linux-4.19-rc8.tar.gz && cd linux-4.19-rc8.tar.gz
cp /boot/config-'uname -r' .config`

Ставим окружение для сборки

sudo yum install -y ncurses-devel gcc make rpm-build redhat-rpm-config

make menuconfig

.config - Linux/x86 4.19.0-rc8 Kernel Configuration
Device Drivers > Microsoft Hyper-V guest support
Microsoft Hyper-V guest support

<*> Microsoft Hyper-V client drivers
<*> Microsoft Hyper-V Utilities driver
<*> Microsoft Hyper-V Balloon driver

make -j4 binrpm-pkg

Ругается из за отсутвия исходнков openssl

CALL    scripts/checksyscalls.sh
DESCEND  objtool
HOSTCC  scripts/extract-cert
scripts/extract-cert.c:21:25: фатальная ошибка: openssl/bio.h: No such file or directory
#include <openssl/bio.h>
                         ^
компиляция прервана.
make[1]: *** [scripts/extract-cert] Error 1
make: *** [scripts] Error 2

yum install openssl-devel

Собираем сразу в пакет (для последующей установки на > 1 машину)
попутно узнаем сколько времени займет сборка ядра

time make -j4 rpm-pkg

...

Processing files: kernel-4.19.0_rc8-1.x86_64
Provides: kernel = 4.19.0_rc8-1 kernel(x86-64) = 4.19.0_rc8-1 kernel-4.19.0-rc8 kernel-drm
Requires(interp): /bin/sh /bin/sh /bin/sh
Requires(rpmlib): rpmlib(CompressedFileNames) <= 3.0.4-1 rpmlib(FileDigests) <= 4.6.0-1 rpmlib(PayloadFilesHavePrefix) <= 4.0-1
Requires(post): /bin/sh
Requires(preun): /bin/sh
Requires(postun): /bin/sh
Processing files: kernel-headers-4.19.0_rc8-1.x86_64
Provides: kernel-headers = 4.19.0_rc8 kernel-headers = 4.19.0_rc8-1 kernel-headers(x86-64) = 4.19.0_rc8-1
Requires(rpmlib): rpmlib(CompressedFileNames) <= 3.0.4-1 rpmlib(FileDigests) <= 4.6.0-1 rpmlib(PayloadFilesHavePrefix) <= 4.0-1
Obsoletes: kernel-headers
Processing files: kernel-devel-4.19.0_rc8-1.x86_64
Provides: kernel-devel = 4.19.0_rc8-1 kernel-devel(x86-64) = 4.19.0_rc8-1
Requires(rpmlib): rpmlib(FileDigests) <= 4.6.0-1 rpmlib(PayloadFilesHavePrefix) <= 4.0-1 rpmlib(CompressedFileNames) <= 3.0.4-1
Checking for unpackaged file(s): /usr/lib/rpm/check-files /root/rpmbuild/BUILDROOT/kernel-4.19.0_rc8-1.x86_64
Wrote: /root/rpmbuild/SRPMS/kernel-4.19.0_rc8-1.src.rpm
Wrote: /root/rpmbuild/RPMS/x86_64/kernel-4.19.0_rc8-1.x86_64.rpm
Wrote: /root/rpmbuild/RPMS/x86_64/kernel-headers-4.19.0_rc8-1.x86_64.rpm
Wrote: /root/rpmbuild/RPMS/x86_64/kernel-devel-4.19.0_rc8-1.x86_64.rpm
Executing(%clean): /bin/sh -e /var/tmp/rpm-tmp.GjdDzO
+ umask 022
+ cd /root/rpmbuild/BUILD
+ cd kernel-4.19.0_rc8
+ rm -rf /root/rpmbuild/BUILDROOT/kernel-4.19.0_rc8-1.x86_64
+ exit 0

real	32m57.255s
user	22m54.364s
sys	6m37.832s

