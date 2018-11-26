## Управление процессами

#### 1. Написать свою реализацию ps ax используя анализ /proc

Исследуем необходимые нам опции `ps`:
Опции `-a` и `-x`:

`-a` выводить все процессы, связанные с конкретным терминалом, кроме главных системных процессов сеанса;

`-x` процессы, отсоединённые от терминала.

Вывод программы `ps -ax`, столбцы и значения, отображенные в них:

- `PID` идентефикатор процесса;
- `TTY` терминал, с которым связан данный процесс;
- `STAT` флаги процесса:
 - `R` процесс выполняется в данный момент \
 - `S` процесс ожидает (т.е. спит менее 20 секунд) \
 - `I` процесс бездействует (т.е. спит больше 20 секунд)
 - `D` процесс ожидает ввода-вывода (или другого недолгого события), непрерываемый
 - `Z` zombie или defunct процесс, то есть завершившийся процесс
 - `T` процесс остановлен
 - `W` процесс в свопе
 - `<` процесс в приоритетном режиме.
 - `N` процесс в режиме низкого приоритета
 - `L` real-time процесс, имеются страницы, заблокированные в памяти.
 - `s` лидер сессии
`TIME` процессорное время, занятое этим процессом;
`COMMAND` 

Что и из каких файлов в /proc мы должны взять и прочитать оттуда данные, мы можем узнать из документа [man7](http://man7.org/linux/man-pages/man5/proc.5.html). Это файлы `/proc/$pid/stat` ,`/proc/$pid/cmdline`, `/proc/$pid/environ`, `/proc/$pid/smaps` и папка, содержащая файловые дескрипторы процессе `/proc/$pid/fd`.

##### PID

Конвейер команд:

```bash
$ ls /proc | grep -P ^[0-9] | sort -n | xargs
```

выведет все папки в `/proc`, содержищие pid запущенных процессов в системе. Далее нам необходимо обойти все эти папки, заглянуть в вышеописанные файлы и прочитать оттуда сведения о каждом процессе.

##### TTY

Смотрим в man, где описаны поля файла `/proc/$pid/stat`:

>(7) tty_nr - The controlling terminal of the process. (The minor device number is contained in the combination of bits 31 to 20 and 7 to 0; the major device number is in bits 15 to 8.)

Если в этом поле есть какие либо сведения, отличные от `0`, то выполняем листинг директории `fd` просматривая ее на предмет терминала `tty` или псевдотерминала `pts`.

```bash
qq=`ls -l $procpid/fd/ | grep -E '\/dev\/tty|pts' | cut -d\/ -f3,4 | uniq`
Tty=`awk '{ if ($7 == 0) {printf "?"} else { printf "'"$qq"'" }}' /proc/$pid/stat`
```

##### STAT

Так же в `/proc/$pid/stat` нас интересуют следующие сведения, которые мы вытащим с помощью `awk` (в коде скрипта `$3`, `$6`, `$8`, `$19`, `$20`), приводим их к порядку вывода `ps` (в скобках указан раздел в man, после краткое описание флага):

 1. $3 - (3) state; - флаг состояния процесса - `D`,`R`,`S`,`T`,`W`,`X`,`Z`
 2. $19 - (19) nice; флаг приоритета 19 (low priority) to -20 (high priority); flags `<`,`N`,` `
 3. if $6==$1 (6) session; флаг, если "начальник" сессии - `s`
 4. $20 (20) num_threads; флаг, если многопоточность, flag - `l`
 5. Флаг блокровки страниц памяти - grep from `/proc/$pid/smaps`
 6. $8 (8) tpgid; процесс выполняется не в фоне, flag - `+`

В п.5 нам нужно посмотреть внутрь файла `/proc/$pid/smaps` на предмет флага блокировки.

Собираем все с помощью такой конструкции:

```bash
Stats=`awk '{ printf $3; \
 if ($19<0) {printf "<" } else if ($19>0) {printf "N"}; \
 if ($6 == $1) {printf "s"}; \
 if ($20>1) {printf "l"}}' $procpid/stat; \
 [[ -n $Locked ]] && printf "L"; \
 awk '{ if ($8!=-1) { printf "+" }}' /proc/$pid/stat`
```

##### TIME 

В документации по `ps` указано, что выводится время жизни процесса состоящее из (14) utime + (15) stime из `/proc/$pid/stat`, это время указано в `clock ticks`, для того что бы получить человекочитаемое время, нужно сумму `utime` и `stime` разделить на `CLK_TCK`, которая есть системная переменная `getconf CLK_TCK`, после чего привести время функцией strftime к виду HH-MM.

```bash
awk -v ticks="$(getconf CLK_TCK)" '{print strftime ("%M:%S", ($14+$15)/ticks)}' /proc/$pid/stat
```  

##### COMMAND

Ну и наконец сведения о парметрах запущенного процесса лежат в `/proc/$pid/cmdline`, man нам говорит:

>This read-only file holds the complete command line for the process, unless the process is a zombie.  In the latter case, there is nothing in this file: that is, a read on this file will return 0 characters. The command-line arguments appear in this file as a set of strings separated by null bytes ('\0'), with a further null byte after the last string.

```
Cmdline=`awk '{ print $1 }' $procpid/cmdline | sed 's/\x0/ /g'`
[[ -z $Cmdline ]] && Cmdline=`strings -s' ' $procpid/stat | awk '{ printf $2 }' | sed 's/(/[/; s/)/]/'`
```

Не всегда там лежит название процесса, иногда нужно заглянуть в `/proc/$pid/stat` если в `cmdline` ничего нет. И побороться с выводом, так как внутри `cmdstat` разделитель - нулевой байт.

После всех преобразований составляем вывод, близкий к выводу `ps`. См. файл [prcss.sh](). Файл нужно запустить от рута - `sudo chmod +x prcss.sh && sudo ./prcss.sh`. 

<details>
  <summary>Вывод `prcss.sh`:</summary>
<pre>
    PID TTY     STAT         TIME COMMAND   
      1 ?       Ss           00:34 /usr/lib/systemd/systemd --switched-root --system --deserialize 21 
      2 ?       S            00:00 [kthreadd]
      3 ?       S            00:02 [ksoftirqd/0]
      5 ?       S<           00:00 [kworker/0:0H]
      6 ?       S            00:05 [kworker/u128:0]
      7 ?       S            00:00 [migration/0]
      8 ?       S            00:00 [rcu_bh]  
      9 ?       R            00:26 [rcu_sched]
     10 ?       S<           00:00 [lru-add-drain]
     11 ?       S            00:17 [watchdog/0]
     13 ?       S            00:00 [kdevtmpfs]
     14 ?       S<           00:00 [netns]   
     15 ?       S            00:00 [khungtaskd]
     16 ?       S<           00:00 [writeback]
     17 ?       S<           00:00 [kintegrityd]
     18 ?       S<           00:00 [bioset]  
     19 ?       S<           00:00 [bioset]  
     20 ?       S<           00:00 [bioset]  
     21 ?       S<           00:00 [kblockd] 
     22 ?       S<           00:00 [md]      
     23 ?       S<           00:00 [edac-poller]
     32 ?       S            00:01 [kswapd0] 
     33 ?       SN           00:00 [ksmd]    
     34 ?       SN           00:05 [khugepaged]
     35 ?       S<           00:00 [crypto]  
     43 ?       S<           00:00 [kthrotld]
     44 ?       S<           00:00 [kmpath_rdacd]
     45 ?       S<           00:00 [kaluad]  
     46 ?       S<           00:00 [kpsmoused]
     48 ?       S<           00:00 [ipv6_addrconf]
     61 ?       S<           00:00 [deferwq] 
     92 ?       S            00:00 [kauditd] 
    112 ?       S<           00:00 [hv_vmbus_con]
    115 ?       S<           00:00 [ata_sff] 
    118 ?       S            00:00 [scsi_eh_0]
    119 ?       S<           00:00 [scsi_tmf_0]
    120 ?       S            00:00 [scsi_eh_1]
    121 ?       S<           00:00 [scsi_tmf_1]
    125 ?       S            00:00 [scsi_eh_2]
    128 ?       S<           00:00 [scsi_tmf_2]
    129 ?       S<           00:00 [storvsc_error_w]
    131 ?       S            00:00 [scsi_eh_3]
    132 ?       S<           00:00 [scsi_tmf_3]
    135 ?       S<           00:00 [storvsc_error_w]
    164 ?       S            00:03 [jbd2/sda1-8]
    165 ?       S<           00:00 [ext4-rsv-conver]
    217 ?       Ss           00:16 /usr/lib/systemd/systemd-journald 
    233 ?       S<           00:05 [kworker/0:1H]
    260 ?       Ss           00:00 /usr/lib/systemd/systemd-udevd 
    280 ?       S<sl         00:01 /sbin/auditd 
    288 ?       S            00:34 [hv_balloon]
    295 ?       S<           00:00 [rpciod]  
    296 ?       S<           00:00 [xprtiod] 
    361 ?       Ss           00:03 /sbin/rpcbind -w 
    362 ?       Ss           00:00 /usr/sbin/hypervvssd -n 
    366 ?       Ssl          00:01 /usr/lib/polkit-1/polkitd --no-debug 
    369 ?       S            00:05 /usr/sbin/chronyd 
    374 ?       Ssl          00:10 /usr/bin/dbus-daemon --system --address=systemd: --nofork --nopidfile --systemd-activation 
    379 ?       Ssl          00:00 /usr/sbin/gssproxy -D 
    388 ?       Ssl          00:44 /usr/sbin/NetworkManager --no-daemon 
    389 ?       Ss           00:06 /usr/lib/systemd/systemd-logind 
    398 tty1    Ss+          00:00 /sbin/agetty --noclear tty1 linux 
    399 ttyS0   Ss+          00:00 /sbin/agetty --keep-baud 115200 38400 9600 ttyS0 vt220 
    403 ?       Ss           00:03 /usr/sbin/crond -n 
    424 ?       S            00:01 /sbin/dhclient -d -q -sf /usr/libexec/nm-dhcp-helper -pf /var/run/dhclient-eth0.pid -lf /var/lib/NetworkManager/dhclient-5fb06bd0-0bb0-7ffb-45f1-d6edd65f3e03-eth0.lease -cf /var/lib/NetworkManager/dhclient-eth0.conf eth0 
    628 ?       Ssl          03:52 /usr/bin/python -Es /usr/sbin/tuned -l -P 
    632 ?       Ss           00:00 /usr/sbin/hypervkvpd -n 
    633 ?       Ssl          02:07 /usr/sbin/rsyslogd -n 
    739 ?       Ss           00:08 /usr/libexec/postfix/master -w 
    741 ?       S            00:01 qmgr -l -t unix -u 
   1057 ?       Ss           00:00 sshd:     
   1060 ?       S            00:00 sshd:     
   1061 pts/0   Ss+          00:00 -bash     
   4864 ?       Ssl          00:00 /usr/sbin/gssproxy -D =BOOT_IMAGE=/boot/vmlinuz-3.10.0-862.14.4.el7.x86_64 
  14047 ?       Ss           00:00 nginx:    
  17773 ?       Ss           00:00 /usr/sbin/lvmetad -f 
  17944 ?       Ssl          01:40 /usr/bin/containerd 
  18191 ?       S            00:03 nginx:    
  19903 ?       S            00:00 pickup -l -t unix -u 
  19930 ?       Ss           00:00 sshd:     
  19933 ?       S            00:00 sshd:     
  19934 pts/1   Ss+          00:00 -bash     
  19960 pts/1   S+           00:00 sudo -i   
  19961 pts/1   S+           00:00 -bash     
  22048 ?       S            00:00 [kworker/0:1]
  24146 ?       S            00:00 [kworker/0:0]
  24147 ?       S            00:00 [kworker/0:2]
  24148 ?       Ss           00:00 sshd:     
  24151 ?       S            00:00 sshd:     
  24152 pts/3   Ss+          00:00 -bash     
  24177 pts/3   S+           00:00 sudo -i   
  24178 pts/3   S+           00:00 -bash     
  26657 ?       Ssl          02:38 /usr/bin/dockerd -H unix:// 
  26806 ?       Sl           00:00 /usr/bin/docker-proxy -proto tcp -host-ip 0.0.0.0 -host-port 5000 -container-ip 172.17.0.2 -container-port 5000 
  26811 ?       Sl           00:11 containerd-shim -namespace moby -workdir /var/lib/containerd/io.containerd.runtime.v1.linux/moby/4840315fef0c065c58c16a733c930310961ce8edafa399c76474f6877b088583 -address /run/containerd/containerd.sock -containerd-binary /usr/bin/containerd -runtime-root /var/run/docker/runtime-runc 
  26827 ?       Ssl          00:30 registry serve /etc/docker/registry/config.yml 
  30452 pts/3   S+           00:00 /bin/bash /root/./prcss.sh 
  30453 pts/3   S+           00:00 /bin/bash /root/./prcss.sh 
  30454 pts/3   S+           00:00 /bin/bash /root/./prcss.sh 
  30455 pts/3   S+           00:00 /bin/bash /root/./prcss.sh 
  30456 pts/3   S+           00:00 /bin/bash /root/./prcss.sh 
  30457 pts/3   S+           00:00 /bin/bash /root/./prcss.sh 
  31457 pts/0   S+           00:00 sudo -i   
  31458 pts/0   S+           00:00 -bash     
  31554 ?       Ss           00:00 /usr/sbin/sshd -D -u0 
  50962 ?       S            00:00 [kworker/u128:2]
</pre></details>

<details>
  <summary>Вывод `ps -ax`:</summary>
<pre>
  PID TTY      STAT   TIME COMMAND
    1 ?        Ss     0:34 /usr/lib/systemd/systemd --switched-root --system --deserialize 21
    2 ?        S      0:00 [kthreadd]
    3 ?        S      0:02 [ksoftirqd/0]
    5 ?        S<     0:00 [kworker/0:0H]
    6 ?        S      0:05 [kworker/u128:0]
    7 ?        S      0:00 [migration/0]
    8 ?        S      0:00 [rcu_bh]
    9 ?        R      0:26 [rcu_sched]
   10 ?        S<     0:00 [lru-add-drain]
   11 ?        S      0:17 [watchdog/0]
   13 ?        S      0:00 [kdevtmpfs]
   14 ?        S<     0:00 [netns]
   15 ?        S      0:00 [khungtaskd]
   16 ?        S<     0:00 [writeback]
   17 ?        S<     0:00 [kintegrityd]
   18 ?        S<     0:00 [bioset]
   19 ?        S<     0:00 [bioset]
   20 ?        S<     0:00 [bioset]
   21 ?        S<     0:00 [kblockd]
   22 ?        S<     0:00 [md]
   23 ?        S<     0:00 [edac-poller]
   32 ?        S      0:01 [kswapd0]
   33 ?        SN     0:00 [ksmd]
   34 ?        SN     0:05 [khugepaged]
   35 ?        S<     0:00 [crypto]
   43 ?        S<     0:00 [kthrotld]
   44 ?        S<     0:00 [kmpath_rdacd]
   45 ?        S<     0:00 [kaluad]
   46 ?        S<     0:00 [kpsmoused]
   48 ?        S<     0:00 [ipv6_addrconf]
   61 ?        S<     0:00 [deferwq]
   92 ?        S      0:00 [kauditd]
  112 ?        S<     0:00 [hv_vmbus_con]
  115 ?        S<     0:00 [ata_sff]
  118 ?        S      0:00 [scsi_eh_0]
  119 ?        S<     0:00 [scsi_tmf_0]
  120 ?        S      0:00 [scsi_eh_1]
  121 ?        S<     0:00 [scsi_tmf_1]
  125 ?        S      0:00 [scsi_eh_2]
  128 ?        S<     0:00 [scsi_tmf_2]
  129 ?        S<     0:00 [storvsc_error_w]
  131 ?        S      0:00 [scsi_eh_3]
  132 ?        S<     0:00 [scsi_tmf_3]
  135 ?        S<     0:00 [storvsc_error_w]
  164 ?        S      0:03 [jbd2/sda1-8]
  165 ?        S<     0:00 [ext4-rsv-conver]
  217 ?        Ss     0:16 /usr/lib/systemd/systemd-journald
  233 ?        S<     0:05 [kworker/0:1H]
  260 ?        Ss     0:00 /usr/lib/systemd/systemd-udevd
  280 ?        S<sl   0:01 /sbin/auditd
  288 ?        S      0:34 [hv_balloon]
  295 ?        S<     0:00 [rpciod]
  296 ?        S<     0:00 [xprtiod]
  361 ?        Ss     0:03 /sbin/rpcbind -w
  362 ?        Ss     0:00 /usr/sbin/hypervvssd -n
  366 ?        Ssl    0:01 /usr/lib/polkit-1/polkitd --no-debug
  369 ?        S      0:05 /usr/sbin/chronyd
  374 ?        Ssl    0:10 /usr/bin/dbus-daemon --system --address=systemd: --nofork --nopidfile --systemd-activation
  379 ?        Ssl    0:00 /usr/sbin/gssproxy -D
  388 ?        Ssl    0:44 /usr/sbin/NetworkManager --no-daemon
  389 ?        Ss     0:06 /usr/lib/systemd/systemd-logind
  398 tty1     Ss+    0:00 /sbin/agetty --noclear tty1 linux
  399 ttyS0    Ss+    0:00 /sbin/agetty --keep-baud 115200 38400 9600 ttyS0 vt220
  403 ?        Ss     0:03 /usr/sbin/crond -n
  424 ?        S      0:01 /sbin/dhclient -d -q -sf /usr/libexec/nm-dhcp-helper -pf /var/run/dhclient-eth0.pid -lf /var/lib/NetworkManager/dhclient-5fb06bd0-0bb0-7
  628 ?        Ssl    3:52 /usr/bin/python -Es /usr/sbin/tuned -l -P
  632 ?        Ss     0:00 /usr/sbin/hypervkvpd -n
  633 ?        Ssl    2:07 /usr/sbin/rsyslogd -n
  739 ?        Ss     0:08 /usr/libexec/postfix/master -w
  741 ?        S      0:01 qmgr -l -t unix -u
 1057 ?        Ss     0:00 sshd: vagrant [priv]
 1060 ?        S      0:00 sshd: vagrant@pts/0
 1061 pts/0    Ss     0:00 -bash
 4864 ?        Ssl    0:00 /usr/sbin/gssproxy -D =BOOT_IMAGE=/boot/vmlinuz-3.10.0-862.14.4.el7.x86_64
14047 ?        Ss     0:00 nginx: master process nginx
17773 ?        Ss     0:00 /usr/sbin/lvmetad -f
17944 ?        Ssl    1:40 /usr/bin/containerd
18191 ?        S      0:03 nginx: worker process
19903 ?        S      0:00 pickup -l -t unix -u
19930 ?        Ss     0:00 sshd: kakoka [priv]
19933 ?        S      0:00 sshd: kakoka@pts/1
19934 pts/1    Ss     0:00 -bash
19960 pts/1    S      0:00 sudo -i
19961 pts/1    S      0:00 -bash
22048 ?        S      0:00 [kworker/0:1]
24146 ?        S      0:00 [kworker/0:0]
24147 ?        R      0:00 [kworker/0:2]
24148 ?        Ss     0:00 sshd: kakoka [priv]
24151 ?        S      0:00 sshd: kakoka@pts/3
24152 pts/3    Ss     0:00 -bash
24177 pts/3    S      0:00 sudo -i
24178 pts/3    S+     0:00 -bash
26657 ?        Ssl    2:38 /usr/bin/dockerd -H unix://
26806 ?        Sl     0:00 /usr/bin/docker-proxy -proto tcp -host-ip 0.0.0.0 -host-port 5000 -container-ip 172.17.0.2 -container-port 5000
26811 ?        Sl     0:11 containerd-shim -namespace moby -workdir /var/lib/containerd/io.containerd.runtime.v1.linux/moby/4840315fef0c065c58c16a733c930310961ce8e
26827 ?        Ssl    0:30 registry serve /etc/docker/registry/config.yml
31457 pts/0    S      0:00 sudo -i
31458 pts/0    S+     0:00 -bash
31554 ?        Ss     0:00 /usr/sbin/sshd -D -u0
32492 pts/1    R+     0:00 ps -ax
50962 ?        S      0:00 [kworker/u128:2]</pre></details>




