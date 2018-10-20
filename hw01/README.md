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
