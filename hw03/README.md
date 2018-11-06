#### 0. Подготовка

Работу над этим заданием начал немного раньше, чем был сам урок на тему LVM и FS, поэтому использую пока старый образ.
По мотивам предыдущих ДЗ, собрал программный RAID1, сделал на нем LVM, который отформатирован в ext4 смонтирован в /. 

Часть этой работы автоматизирована и находится в файле `scripts/create_raid`, который при `vagrant up` создает md0, поверх него 
physical volume (PV) - размером в 40G, далее volume group (VG) - vg0 и уже на ней logical volume - lvm_root.
Часть в файле скрипта закомментирована, ее следует выполнить вручную.

```sh
# chroot /mnt
#
# sed -i.bak '/UUID/d' /etc/fstab && blkid | grep vg0-lvm_root | awk -F\" '{print "UUID="$2" / ext4 defaults 0 0"}' >> /etc/fstab
# mv /boot/initramfs-$(uname -r).img /boot/initramfs-$(uname -r).img.old && dracut /boot/initramfs-$(uname -r).img $(uname -r)
# grub2-mkconfig -o /boot/grub2/grub.cfg
# grub2-install /dev/sda
# grub2-install /dev/sdb
```

Так как у нас используется SELinix, то, цитата:

>The recommended method for relabeling a file system is to reboot the machine. This allows the init process to perform the relabeling, ensuring that applications have the correct labels when they are started and that they are started in the right order. If you relabel a file system without rebooting, some processes may continue running with an incorrect context. Manually ensuring that all the daemons are restarted and running in the correct context can be difficult.

```sh
# touch /mnt/.autorelabel
# exit
# reboot
```

Теперь у нас - два в одном :) и надо что-то с этим делать.

#### 1. Уменьшить ext4 / до 8 Gb

Если виртуалка где-то далеко, с KVM все сложно, а нам необходимо зачем-то уменьшить корневой раздел :], то имеется 2 варианта:

1. Использовать pivot_root или chroot. Создаем, например, в оперативной памяти tempfs, переносим туда файлы, делаем туда перенос корневного раздела, размонтируем старый корень и двигаем разделы как хотим, далее перенос в обратном порядке. В общем, мучительно долго. 

2. Использовать хуки при загрузке. Этот способ хорош тем, что при загрузке системы в стадию перед монитрованием вставляется написанный нами скрипт для уменьшения корневого раздела. Но если ошибиться в этом, то это будет дорого стоить.

Поехали:

Сначала, не забудем включить логгирование загрузки.

```sh
# mkdir /var/log/journal && chown :systemd-journal /var/log/journal
# systemctl restart systemd-journald
```

Наш скрипт для изменения раздела перед монитрованием:

```sh
# mkdir /usr/lib/dracut/modules.d/91resizerootfs
# vi /usr/lib/dracut/modules.d/91resizerootfs/module-setup.sh
# vi /usr/lib/dracut/modules.d/91resizerootfs/resizeroot-local.sh
```
Код модулей находится в репозитории.

Текущий размер раздела /:
```sh
# df -h
```
>Filesystem                Size  Used Avail Use% Mounted on \
>/dev/mapper/vg0-lvm_root   20G  3.0G   16G  17% /

Внутри скрипта команда для изменения размера раздела:

```sh
lvm lvreduce --config 'global {locking_type=1}' -y -r -L -12G /dev/vg0/lvm_root
```
Ее опции:

-r - говорит ей учитывать, что на разделе есть файловая система и сначала надо изменить ее
--config 'global {locking_type=1}' - говорит о том, что можно работать в режиме read-write
(это, видимо тоже тема будущего, не до конца это понял)

Для изменения размера утилита lvm использует утилиту fsadm, которая в свою очередь использует ряд других утилит. Что кстати удобно, позволяет изменять раздел томов вместе с размером файловых систем на них (не относится к xfs).

Добавляем "это все" в наш конфиг, пересобираем initramfs:

```sh
# dracut --add resizeroot --install 'fsadm date test head cut tune2fs blockdev resize2fs' --force
```

Проверяем все ли на месте:

```sh
# lsinitrd -m | grep resizeroot && lsinitrd | grep fsadm
# reboot
```

После перезагрузки:

```sh
# df -hT
```

>Filesystem               Type      Size  Used Avail Use% Mounted on \
>/dev/mapper/vg0-lvm_root ext4      7.8G  2.9G  4.5G  40% /

Том с файловой системой уменьшился до заданного значения. 
Смотрим лог загрузки:

```sh
# journalctl -b-1
```

>Oct 29 21:17:15 otuslinux dracut-pre-mount[465]: Resizing the filesystem on /dev/mapper/vg0-lvm_root to 2097152 (4k) blocks. \
>Oct 29 21:17:15 otuslinux dracut-pre-mount[465]: The filesystem on /dev/mapper/vg0-lvm_root is now 2097152 blocks long. \
>Oct 29 21:17:15 otuslinux dracut-pre-mount[465]: Size of logical volume vg0/lvm_root changed from 20.00 GiB (5120 extents) to 8.00 GiB (2048 extents). \
>Oct 29 21:17:15 otuslinux dracut-pre-mount[465]: Logical volume vg0/lvm_root successfully resized.


Наблюдаем, что размер уменьшился до заданных 8 гигабайт.

Напоследок убираем из initrd хуки:

```sh
dracut --omit resizeroot --force
```

#### 2. Уменьшить xfs / до 8 Gb

Для xfs особенностей больше. Общий смысл действий таков: делаем временный том на LVM, форматируем его в xfs, переносим туда данные, уменьшаем размер исходного тома, переносим данные обратно, удаляем временный том. Для переноса файлов / будем использовать xfsdump.

```sh
# yum install xfsdump
```

По аналогии с предыдущей частью:

```sh
mkdir /usr/lib/dracut/modules.d/91resizerootxfs/
```

И в файле resizerootxfs-local.sh пишем:

```sh
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
```

Отметим, во первых, что xfsdump работает только со смонтированными томами, во-вторых, нужно сохранить uuid (не факт, что нужно, но без этого у меня почему-то не завелось). Укажем его явно при создании новой файловой системы. Во вторых, можно уменьшить скрипт, удалив том lvm_root и переименовать раздел temp_xfs в lvm_root - `lvm lvrename vg0 temp_xfs lvm_root`.

После перезагрузки, наблюдаем вывод `df -hT`:

>Filesystem               Type      Size  Used Avail Use% Mounted on \
>/dev/mapper/vg0-lvm_root xfs       8.0G  2.9G  5.1G  37% /

После перезагрузки системы не забудем убрать модуль из dracut `dracut --omit resizerootxfs -f`.

#### 3. Практика по LVM.

Результаты по пунктам:

- выделить том под /home
- выделить том под /var
- /var - сделать в lvm mirror
- /home - сделать том для снапшотов
- прописать монтирование в fstab
- попробовать с разными опциями и разными файловыми системами ( на выбор)

- сгенерить файлы в /home/
- снять снэпшот
- удалить часть файлов
- восстановиться со снапшота
- залоггировать работу можно с помощью утилиты script

* на нашей куче дисков попробовать поставить btrfs/zfs - с кешем, снэпшотами - разметить здесь каталог /opt

находятся в файле `lvm_practice.txt`.

Из интересного, хочется отметить, что при добавлении дисков в Vagrantfile так и не удалось добиться того, что бы они отображались в системе при `vagrant reload`.

В качестве дополнительных дисков я добавил несколько loop устройств:

```sh
dd if=/dev/zero of=/loops/loopfile1 bs=1M count=1000
losetup /dev/loop1 /loops/loopfile1
...
pvcreate /dev/loop1 /dev/loop2
vgcreate vg1 /dev/loop2 /dev/loop2
lvcreate -l -L 900M -m1 -n lv-var vg1
```

И уже на них создан том и примонтирован в каталог /var.

Так же был создан том и примонтирован в каталог /opt. На этом томе файловая система btrfs.
С ней были выполнены разные манипуляции - добавление устройства, удаление устройства, создание снепшотов, создание субтомов и тд.

```sh
mkfs.btrfs /dev/vg0/btrfs
mkfs.btrfs /dev/loop3
mount /dev/vg0/btrfs /opt
btrfs subvolume snapshot /opt /opt
...
btrfs device add /dev/loop3 /opt
btrfs device delete /dev/loop3 /opt
btrfs subvolume create /opt/vol1
```
