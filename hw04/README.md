#### 0. Подготовка.

Для того, что бы /boot был на был отдельном разделе пришлось сделать свой vagrnat box.

В VirtualBox создал VM с именем Centos7 и нужными мне параметрами, скачал новый iso [CentOS-7-x86_64-Minimal-1804](http://mirror.corbina.net/pub/Linux/centos/7.5.1804/isos/x86_64/CentOS-7-x86_64-Minimal-1804.iso). Разметил диск, сделав под /boot раздел sda1 и подготовил внутренности VM для дальнейшего использования в качестве шаблона. Достаточно много необходимо сделать, примеры в сети на эту тему имеются.

```sh
$ useradd vagrant
$ passwd vagrant
$ usermod -aG wheel vagrant
...
$ systemctl poweroff
```

Далее:

```sh
$ vagrant package --base Centos7
$ vagrant box add Centos7 package.box
```

TODO: сделать приватный репозитарий.


#### 1. Вход в систему без пароля.

Вход в систему без пароля можно осуществить меняя конфигурацию файлов загрузчика, добавляя или изменяя ряд параметров.

1. init=/sysroot/bin/sh

Этот способ позволяет запустить шелл, указав это директивно. Перед переключеним контекста на дальнейший старт системы после загрузки ядра и монтирования файловых систем.

>linux16 /vmlinuz-3.10.0-862.14.4.el7.x86_64 root=/dev/mapper/centos-root `rw init=/sysroot/bin/sh` rhgb quiet rd.auto=1 rd.lvm=1 rd.lvm.vg=centos rg.lvm.lv=root rg.lvm.lv=swap rg.lvm.lv=boot 

2. rd.break

Этот способ позволяет получить шелл указав конкретное место, в котором следует это сделать при загрузке модулей при старте initrd:

>linux16 /vmlinuz-3.10.0-862.14.4.el7.x86_64 root=/dev/mapper/centos-root ro rhgb quiet rd.auto=1 rd.lvm=1 rd.lvm.vg=centos rg.lvm.lv=root rg.lvm.lv=swap rg.lvm.lv=boot `rd.break=pre-mount`

В данном случае, указан хук `pre-mount` - "перед монированием файловой системы".

Хуки dracut подробно описаны в документации по dracut.

3. rd.shell

Официальный способ получить "emergency shell" при загрузке системы.

>allow dropping to a shell, if root mounting fails

>linux16 /vmlinuz-3.10.0-862.14.4.el7.x86_64 root=/dev/mapper/centos-root ro rhgb quiet rd.auto=1 rd.lvm=1 rd.lvm.vg=centos rg.lvm.lv=root rg.lvm.lv=swap rg.lvm.lv=boot `rd.shell`

#### 2. Переименование VolumeGroup

Посмотрим именование группы томов - `vgs`:

>centos   2   3   0 wz--n- 19,99g 4,00m

Изменяем имя тома командной `vgrename centos cent`.

Далее, внесем изменения в конфигурационные файлы:

```sh
$ sed -i 's/centos/cent/g' /boot/grub2/grub.cfg && sed -i 's/centos/cent/g' /etc/fstab
```

Сделаем активной группу томов и обновим метаданные логических томов на этой vg. Также пересоберем с новыми параметрами initramfs. 

```sh
$ vgchange -ay
$ lvchange /dev/cent/{boot,root,swap} --refresh
$ dracut -f
```

Перезагружаемся и выполняем `vgs`:

>cent   2   3   0 wz--n- 19,99g 4,00m

#### 3. Модуль initrd

Полезный модуль, который делает изменение размера тома lvm с xfs в [домашнем задании №3, часть 2](https://github.com/kakoka/otus-homework/tree/master/hw03#2-%D1%83%D0%BC%D0%B5%D0%BD%D1%8C%D1%88%D0%B8%D1%82%D1%8C-xfs--%D0%B4%D0%BE-8-gb)

#### 4. Перемещаем /boot на LVM, используем grub2

Вывод `lsblk` до перемещения раздела на LVM:

>NAME            MAJ:MIN RM SIZE RO TYPE MOUNTPOINT \
>sda               8:020G  0 disk                   \
>├─sda1            8:1 1G  0 part /boot             \
>└─sda2            8:219G  0 part                   \
>  ├─centos-root 253:017G  0 lvm  /                 \
>  └─centos-swap 253:1 2G  0 lvm  [SWAP]

```sh
$ mkdir /newboot && rsync -av /boot/ /newboot/
$ umount /boot/
$ pvcreate /dev/sda1
$ vgextend centos /dev/sda1
$ lvcreate -L 0.99G -n boot centos
$ mkfs.ext4 /dev/centos/boot 
$ mount /dev/centos/boot /boot
$ rsync -av /newboot/ /boot/
$ rm -rf /newboot/
$ nano /etc/fstab 
```

Заменим строчку в /etc/fstab:

> /dev/mapper/centos-boot /boot ext4 defaults 1 2

```sh
$ nano /etc/default/grub 
```

Добавим в значения:

> GRUB_CMDLINE_LINUX='rhgb quiet rd.auto=1 rd.lvm=1 rd.lvm.vg=centos rg.lvm.lv=root rg.lvm.lv=swap rg.lvm.lv=boot' \
> GRUB_PRELOAD_MODULES='lvm'

```sh
$ grub2-mkconfig -o /etc/grub2.cfg 
$ grub2-install /dev/sda
$ reboot
```

Вывод `lsblk` после перемещения раздела на LVM:

>NAME            MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT \
>sda               8:0 20G  0 disk                   \
>├─sda1            8:1  1G  0 part                   \
>│ └─centos-boot 253:2    0 1016M  0 lvm  /boot      \
>└─sda2            8:2 19G  0 part                   \
>  ├─centos-root 253:0 17G  0 lvm  /                 \
>  └─centos-swap 253:1  2G  0 lvm  [SWAP]     
