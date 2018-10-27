#### 0. Vagrantfile.

В VirtualBox будем делать старт Centos7 с RAID1, для этого добавим диск такого же размера как и тот, на котором она установлена.
В Vagrantfile изменим две строки:
##### 0.1 Добавим диск размером 40gb

```js
       :disks => {
                :sata1 => {
                        :dfile => './sata1.vdi',
                        :size => 40960,
                        :port => 1
                }

        }
```

##### 0.2 Сделаем его динамическим:

```js
vb.customize ['createhd', '--filename', dconf[:dfile], '--variant', 'Standard', '--size', dconf[:size]]
```

#### 1. Разметка диска.

Сделаем копию разделов на второй диск:

```sh
$ sfdisk -d /dev/sda | sfdisk --force /dev/sdb
```

Изменим тип раздела на Linux raid:

```sh
$ parted /dev/sdb set 1 raid on
```

#### 2. Перенос системы на riad.

##### 2.1 Собираем raid1, форматируем и синхронизируем его с исходной системой.

```sh
$ mdadm --zero-superblock --force /dev/sdb1
$ mdadm --create /dev/md0 --level=1 --raid-disks=2 missing /dev/sdb1
$ mkfs.ext4 /dev/md0
```

Проверим, что raid запустился `cat /proc/mdstat` и найдем UUID /dev/md0 `blkid | grep md0`:

> /dev/md0: UUID="1e8d7143-5b7a-4203-9fdb-a79f2fc7779a" TYPE="ext4"

```sh
$ mount /dev/md0 /mnt/
```

##### 2.2 Синхронизируем файлы на диске между исходынм диском и raid. Меняем окружение, chroot нужен для подготовки старта с md0.

```sh
$ rsync --progress -av --exclude /proc --exclude /run --exclude /dev --exclude /sys --exclude /mnt  / /mnt/
$ mkdir /mnt/{proc,run,sys,dev,mnt}
$ mount --bind /proc /mnt/proc && mount --bind /dev /mnt/dev && mount --bind /sys /mnt/sys && mount --bind /run /mnt/run
$ chroot /mnt/ 
```

##### 2.3 Правим /etc/fstab, /etc/mdadm/mdadm.conf, /etc/defaults/grub, grub.cnf, собираем initrd.

```sh
$ ls -l /dev/disk/by-uuid | grep md >> /etc/fstab
```

Меняем UUID корневого раздела:

```sh
$ vi /etc/fstab
```

```sh
$ mdadm --examine --scan >> /etc/mdadm/mdadm.conf
$ cat /etc/mdadm/mdadm.conf
```

Собираем новый initrd с поддержкой загрузки с raid:

```sh
$ mv /boot/initramfs-$(uname -r).img /boot/initramfs-$(uname -r).img.old
$ dracut /boot/initramfs-$(uname -r).img $(uname -r)
```

##### 2.4 Конфигурируем и устанавливаем Grub.

Необходимо добавить в конфигурацию загрузчика опцию rd.auto = 1, потому что, цитата из документации:

> rd.auto=1. enable autoassembly of special devices like cryptoLUKS, dmraid, mdraid or lvm

позволяет запускаться с разных вариантов томов (raid, lvm и тд).

```sh
$ echo "GRUB_CMDLINE_LINUX='rhgb quiet rd.auto=1'" >> /etc/default/grub
```

Собираем конфиг:

```sh
$ grub2-mkconfig -o /boot/grub2/grub.cfg
```

проверяем на месте ли UUID raid:

```sh
$ cat /boot/grub2/grub.cfg | grep 1e8d7143-5b7a-4203-9fdb-a79f2fc7779a
```

>linux16 /boot/vmlinuz-3.10.0-862.14.4.el7.x86_64 root=UUID=1e8d7143-5b7a-4203-9fdb-a79f2fc7779a ro rhgb quiet rd.auto=1

и устанавливаем

```sh
$ grub2-install /dev/sda
$ grub2-install /dev/sdb
```

покидаем chroot
```sh
$ exit && reboot
```
#### 3. После перезагрузки

Убеждаемся что мы стартовали с raid:

```sh
$ df -h
```

>Filesystem      Size  Used Avail Use% Mounted on \
>/dev/md0         40G  4.0G   34G  11% /

и добавляем исходный диск в raid:

```sh
$ parted /dev/sda set 1 raid on
$ mdadm --manage --add /dev/md0 /dev/sda1
```

>mdadm: added /dev/sda1

```sh
$ watch -d -n1 "cat /proc/mdstat"
```

Наблюдаем восстановление целостности массива:

>Every 1.0s: cat /proc/mdstat \
>Personalities : [raid1] \
>md0 : active raid1 sda1[2] sdb1[1] \
>      41908224 blocks super 1.2 [2/1] [_U] \
>      [===>.................]  recovery = 15.7% (6598272/41908224) finish=2.9min speed=199876K/sec \
>unused devices: <none>
