В Centos7 нет поддержки файловых систем ext2-4, поэтому поставим пакет e2fsprogs:
```sh
$ sudo -i
$ yum install e2fsprogs
```

Смотрим, что у нас есть

```sh
$ lsscsi
```

>[0:0:0:0]    disk    ATA      VBOX HARDDISK    1.0   /dev/sda 
>[3:0:0:0]    disk    ATA      VBOX HARDDISK    1.0   /dev/sdb 
>[4:0:0:0]    disk    ATA      VBOX HARDDISK    1.0   /dev/sdc 
>[5:0:0:0]    disk    ATA      VBOX HARDDISK    1.0   /dev/sdd 
>[6:0:0:0]    disk    ATA      VBOX HARDDISK    1.0   /dev/sde 
>[7:0:0:0]    disk    ATA      VBOX HARDDISK    1.0   /dev/sdf 
>[8:0:0:0]    disk    ATA      VBOX HARDDISK    1.0   /dev/sdg 
>[9:0:0:0]    disk    ATA      VBOX HARDDISK    1.0   /dev/sdh 
>[10:0:0:0]   disk    ATA      VBOX HARDDISK    1.0   /dev/sdi 

```sh
$ lshw -short | grep disk
```

>>>
/0/100/1.1/0.0.0    /dev/sda   disk        42GB VBOX HARDDISK
/0/100/d/0          /dev/sdb   disk        262MB VBOX HARDDISK
/0/100/d/1          /dev/sdc   disk        262MB VBOX HARDDISK
/0/100/d/2          /dev/sdd   disk        262MB VBOX HARDDISK
/0/100/d/3          /dev/sde   disk        262MB VBOX HARDDISK
/0/100/d/4          /dev/sdf   disk        262MB VBOX HARDDISK
/0/100/d/5          /dev/sdg   disk        262MB VBOX HARDDISK
/0/100/d/6          /dev/sdh   disk        262MB VBOX HARDDISK
/0/100/d/7          /dev/sdi   disk        262MB VBOX HARDDISK
>>>

Видим 8 дисков по 262 мегабайта, создадим на них RAID50.

#### 1. Создаем на дисках gpt раздел и партиции:

```sh
for d in /dev/sd{b,c,d,e,f,g,h,i}; do parted -s $d mktable gpt; done && \
for d in /dev/sd{b,c,d,e,f,g,h,i}; do parted -s $d mkpart primary 0% 20% && parted -s $d mkpart primary 20% 90% && parted -s $d mkpart 90% 100%; done
```

#### 2. Соберем RAID 50 на размеченных разделах дисков.

##### 2.1 Собираем 2xRAID5:
```sh
$ mdadm --create --verbose /dev/md0 -l 5 -n 4 /dev/sd{b,c,d,e}1 && \
mdadm --create --verbose /dev/md1 -l 5 -n 4 /dev/sd{f,g,h,i}1
```

##### 2.2 Собираем RAID0 из 2-х RAID5, создаем на нем партицию, форматируем в ext4, монтируем в /raid, попутно создадим тестовый набор файлов:

```sh
$ mdadm --create --verbose /dev/md3 -l 0  -n 2 /dev/md{0,1}  && \
parted -s /dev/md3 mktable gpt && \
parted -s /dev/md3 mkpart primary ext4 0% 100% && \
mkfs.ext4 /dev/md3p1 && \
mkdir -p /raid && mount /dev/md3p1 /raid && \
for i in $(seq 1 10); do touch file /raid/file$i && truncate -s 10240 /raid/file$i; done && \
df -h /raid
```
>>>
Filesystem      Size  Used Avail Use% Mounted on
/dev/md3p1      262M  2.1M  242M   1% /raid
>>>

Добавим конфигурационный файл для mdadm 

mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf

#### 3. Ломаем и чиним RAID50.

Сломаем два диска в массиве md0:
```sh
$ mdadm /dev/md0 --fail /dev/sdc1 && mdadm /dev/md0 --fail /dev/sdb1
$ mdmon -F -a 
$ watch -n .1 cat /proc/mdstat
```
>>>
Personalities : [raid6] [raid5] [raid4] [raid0] 
md3 : active raid0 md1[1] md0[0]
      284672 blocks super 1.2 512k chunks
md1 : active raid5 sdi1[4] sdh1[2] sdg1[1] sdf1[0]
      144384 blocks super 1.2 level 5, 512k chunk, algorithm 2 [4/4] [UUUU]
md0 : active raid5 sde1[4](F) sdd1[2] sdb1[0]
      144384 blocks super 1.2 level 5, 512k chunk, algorithm 2 [4/3] [U_U_]
>>>

Удалим их:

```sh
$ mdadm /dev/md0 --remove /dev/sdb1 && mdadm /dev/md0 --remove /dev/sdc1
```

Так как /dev/md0 - RAID5 из 4 дисков, то он не взлетит автоматически при простом добавлении дисков. Cистема будет сообщать, что невозможно стартовать /dev/md0, потому что нет необходимого количества дисков для этой операции. Поэтому, мы должны  размонтировать и остановить RAID0 - /dev/md3, куда входит /dev/md0. Далее необходимо пересобрать /dev/md0 вручную, из стартовать заново /dev/md3. Выполняем:

Размонтируем и останавливаем /dev/md3 и /dev/md0:

```sh
$ umount /raid && mdadm -S /dev/md3
$ mdadm -S /dev/md0
```

Выполним пересборку массива /dev/md0:
```sh
$ mdadm --assemble --force /dev/md0 /dev/sdb1 /dev/sdc1 /dev/sdd1 /dev/sde1
```

Далее стартуем /dev/md3:

```sh
$ mdadm --assemble --scan && \
lsblk /dev/md3
```

>>>
NAME    MAJ:MIN RM  SIZE RO TYPE  MOUNTPOINT
md3       9:3    0  278M  0 raid0 
`-md3p1 259:0    0  278M  0 md    /raid
>>>

```sh
$ mount /dev/md3p1 /raid
```

Cмотрим `ls -lah /raid` 

>>>
-rw-r--r--. 1 root root 10240 Oct 24 16:05 file1
-rw-r--r--. 1 root root 10240 Oct 24 16:05 file10
-rw-r--r--. 1 root root 10240 Oct 24 16:05 file2
-rw-r--r--. 1 root root 10240 Oct 24 16:05 file3
-rw-r--r--. 1 root root 10240 Oct 24 16:05 file4
-rw-r--r--. 1 root root 10240 Oct 24 16:05 file5
-rw-r--r--. 1 root root 10240 Oct 24 16:05 file6
-rw-r--r--. 1 root root 10240 Oct 24 16:05 file7
-rw-r--r--. 1 root root 10240 Oct 24 16:05 file8
-rw-r--r--. 1 root root 10240 Oct 24 16:05 file9
drwx------. 2 root root 12288 Oct 24 14:50 lost+found
>>>

Наши файлы на месте.

#### 4. Vagrantfile и скрипт для создания RAID 

В Vagrantfile добавлено еще 4 диска, файл для создания raid при создании виртуальной машины находится в scripts/create-raid и добавлен в Vagrantfile.
