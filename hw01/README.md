Выясним, что у нас за система:
```console
$ uname -a
```
>Linux localhost.localdomain 3.10.0-862.14.4.el7.x86_64 #1 SMP Wed Sep 26 15:12:11 UTC 2018 x86_64 x86_64 x86_64 GNU/Linux

```console
$ cat /etc/centos-release
```

>CentOS Linux release 7.5.1804 (Core)

Скачиваем ядро из kernel.org, распаковываем его, копируем конфигурацию текущего ядра в директорию с исходниками ядра для сборки:

```console
cd /usr/src/kernels/ && \
wget https://git.kernel.org/torvalds/t/linux-4.19-rc8.tar.gz && \
tar -zxvf linux-4.19-rc8.tar.gz && cd linux-4.19-rc8 && \
cp /boot/config-'uname -r' .config
```

Ставим окружение для сборки:

```console
$ sudo yum install -y ncurses-devel gcc make rpm-build redhat-rpm-config
```

Запускаем конфигурирование опций для сборки ядра:

```console
$ make menuconfig
```
Например, добавим драйвера для корректной работы Centos7 под гипервизором Microsoft Hyper-V в ядро:

> Linux/x86 4.19.0-rc8 Kernel Configuration 
> Device Drivers 
> Microsoft Hyper-V guest support 
> + Microsoft Hyper-V client drivers 
> + Microsoft Hyper-V Utilities driver 
> + Microsoft Hyper-V Balloon driver

Собираем ядро сразу в пакет, для последующей установки на больше, чем на одну машину. Собираем с опцией -j4 - сборка в 4 потока. Попутно узнаем сколько времени займет сборка ядра:

```console
$ time make -j4 rpm-pkg
```

Сборка оканчивается ошибкой из за отсутвия исходнков openssl.

>scripts/extract-cert.c:21:25: фатальная ошибка: openssl/bio.h: No such file or directory \
>#include <openssl/bio.h> \
>компиляция прервана.

Доставим нужный пакет:

```console
$ sudo yum install openssl-devel
```

Еще раз:

```console
$ time make -j4 rpm-pkg
```

>Processing files: kernel-4.19.0_rc8-1.x86_64 \
>... \
>Wrote: ~/rpmbuild/SRPMS/kernel-4.19.0_rc8-1.src.rpm \
>Wrote: ~/rpmbuild/RPMS/x86_64/kernel-4.19.0_rc8-1.x86_64.rpm \
>Wrote: ~/rpmbuild/RPMS/x86_64/kernel-headers-4.19.0_rc8-1.x86_64.rpm \
>Wrote: ~/rpmbuild/RPMS/x86_64/kernel-devel-4.19.0_rc8-1.x86_64.rpm 
>
>real    32m57.255s \
>user    22m54.364s \
>sys     6m37.832s 

Сборка прошла успешно, можно добавлять ядро в загрузчик.
