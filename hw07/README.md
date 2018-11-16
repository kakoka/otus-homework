## PAM

#### 1. Запретить всем пользователям, кроме группы admin логин в выходные и праздничные дни

##### 1.1 pam_time

Создадим группы `admin` и `myusers` и добавим пользователей vasya, petya и kolya:
 
```bash
$ groupadd myusers
$ groupadd admin
$ useradd -g myusers vasya
$ useradd -g myusers petya
$ useradd -g admin kolya
```

Добавим правило в /etc/security/time.conf, запрещающее вход в выходные дни всем пользователям, кроме тех, кто принадлежит группе admin:

```bash
sshd;*;!admin;!Wk0000-2400
```

Добавим правило в /etc/pam.d/sshd

```bash
account required pam_time.so
```

Пробуем зайти по ssh:

```bash
$ ssh petya@localhost

petya@localhost's password:
Authentication failed.
```
Наше правило сработало. Теперь все пользователи, кроме пользователей группы admin не могут зайти по ssh на хост.

##### 1.2 pam_script

Все, что описано в 1.1 было б здорово, если бы не два "но": первое "но", группы не работают в pam_time (вместо `sshd;*;!admin;!Wk0000-2400` нужно писать `sshd;*;petya|vasya;!Wk0000-2400`); второе "но", не учитываются праздничные дни. Если с первым что-то можно еще сделать, то с российскими выходными придется изобретать велосипед. 

Добавим правило в /etc/pam.d/sshd

```bash
account required pam_script.so
```

В `/etc/pam-script` нужно сделать 2 вещи. Первое: проверить принадлежность пользователя группе 'admin'. Если пользователь принадлежит группе, то пустить в систему (завершить скрипт с кодом 0). Второе: если не принадлежит, то дополнительно проверить принадлежность группе 'myusers'. Далее следует проверить дату. Если пользователь принадлежит группе 'myusers', а дата совпадает со списком праздничных дат и/или выходными днями недели (сб-вск), то скрипт завершается с кодом 1, в систему пользователь не попадет, в противном случае пустить (код 0). 
И зачем товарищ `Andrew G. Morgan`, автор `pam_time` в `time.conf` решил не работать с группами? 

Проверяем гипотезу:

```bash
$ grep "admin.*kolya" /etc/group
> admin:x:1005:kolya
```

Ага, из документации можно узнать, что у нас есть `$PAM_USER` - переменная, которое содержит имя пользователя при логине.

```bash
#!/usr/bin/env bash

prazdniki=(1511 0101 0201 0301 0401 0501 0601 0701 0801 2302 \ 
2402 2502 0803 0903 1003 1103 2904 3004 0105 0205 0905 \ 
1006 1106 1206 0311 0411 0511 3012 3112)                        # согласно календарю праздников РФ за 2018 год :]

if [[ `grep "admin.*$(echo $PAM_USER)" /etc/group` ]]           # принадлежит ли пользователь группе 'admin'
 then
   exit 0                                                       # если в группе, то пускаем
elif [[ `grep "myusers.*$(echo $PAM_USER)" /etc/group` ]]       # если кто-то другой, но из группы 'myusers'
 then
   if [[ " `date +%u` " > " 5 " ]]                              # смотрим день недели, должен быть меньше 5 что бы попасть внурть
    then
     exit 1
   elif [[ " ${prazdniki[@]} " =~ " `date +%d%m` " ]]          # смотрим, не попадаем ли в праздники 
    then
     exit 1
   else
     exit 0                                                    # если все хорошо, пускаем внутрь
    fi
else
   exit 0                                                      # если пользователь вне групп 'admin', 'myusers'
```

Проверяем (проверим все варианты работы - текущая дата в списке праздников, текущий день недели - что б срабатывало), в репозитории лежит скрипт, где попытки входа записываются в лог:

<pre>
[Thu Nov 15:root@otuslinux~]# ssh vagrant@localhost
vagrant@localhost's password:
Hi!
[Thu Nov 15:vagrant@otuslinux~]$ logout
[Thu Nov 15:root@otuslinuxetc]# ssh vasya@localhost
vasya@localhost's password:
Authentication failed.
[Thu Nov 15:root@otuslinuxetc]# ssh kolya@localhost
kolya@localhost's password:
[kolya@otuslinux ~]$ more /tmp/login.log
[15-11-15] anohter user vagrant shall pass
[15-11-15] vasya - weekend now!
[15-11-15] kolya - you are welcome!
[15-11-15] vasya - is party day!
[15-11-15] vasya - you may pass
</pre>

И еще, если:
```bash
$ ls -la /etc/pam_script*
```
То:
<pre>
-rwxr-xr-x. 1 root root  688 Nov 15 15:58 /etc/pam_script
-rwxr-xr-x. 1 root root 3837 Aug 23  2016 /etc/pam_script.old
lrwxrwxrwx. 1 root root   10 Nov 15 06:57 /etc/pam_script_acct -> pam_script
lrwxrwxrwx. 1 root root   10 Nov 15 06:57 /etc/pam_script_auth -> pam_script
lrwxrwxrwx. 1 root root   10 Nov 15 06:57 /etc/pam_script_passwd -> pam_script
lrwxrwxrwx. 1 root root   10 Nov 15 06:57 /etc/pam_script_ses_close -> pam_script
lrwxrwxrwx. 1 root root   10 Nov 15 06:57 /etc/pam_script_ses_open -> pam_script
</pre>

Все /etc/pam_script* указывают на один файл. Это для заметки.

#### 2. Дать конкретному пользователю права рута.

##### 2.1 Добавим пользователя в `/etc/sudoers` строчку:

Добавим в `/etc/sudoers` строчку:

```bash
kolya ALL=(ALL) ALL
```

Пробуем зайти как kolya и vasya и ввести команду `sudo -i`:

<pre>
[Wed Nov 14:root@otuslinux~]# ssh kolya@localhost
Last login: Wed Nov 14 09:29:38 2018 from 192.168.11.1
[kolya@otuslinux ~]$ sudo -i
[sudo] password for kolya:
[root@otuslinux ~]# logout
[kolya@otuslinux ~]$ logout
Connection to localhost closed.
[Wed Nov 14:root@otuslinux~]# ssh vasya@localhost
vasya@localhost's password:
Last login: Wed Nov 14 09:29:21 2018 from 192.168.11.1
[vasya@otuslinux ~]$ sudo -i
[sudo] password for vasya:
vasya is not in the sudoers file.  This incident will be reported.
</pre>

Пользователь kolya может получить права суперпользователя, а vasya - нет.

##### 2.2 pam_groups.so

Добавим в `/etc/pam.d/sshd` в самое начало строчку:

```bash
auth required pam_group.so
```

а в файл `/etc/security/group.conf`

```bash
sshd;*;kolya;Al0000-2400;wheel
```
Таким образом, при входе в систему, пользователь kolya (который входит в группу admin, кстати, вместо 'kolya' можно добавить всю группу admin - написать '%admin' ) получит членство в группе wheel, а члены этой группы могут получать права суперпользователя.

<pre>
ssh kolya@localhost
kolya@localhost's password:
Last login: Thu Nov 15 13:47:17 2018 from ::1
[kolya@otuslinux ~]$ sudo -i
[sudo] password for kolya:
[root@otuslinux ~]# cat /etc/sudoers | grep kolya
#kolya   ALL=(ALL)       ALL
[root@otuslinux ~]# cat /etc/sudoers | grep wheel
## Allows people in group wheel to run all commands
%wheel	ALL=(ALL)	ALL
# %wheel	ALL=(ALL)	NOPASSWD: ALL
</pre>
