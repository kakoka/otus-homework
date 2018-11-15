## PAM

#### 1. Запретить всем пользователям, кроме группы admin логин в выходные и праздничные дни

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
$ ssh petya@192.168.11.101

petya@192.168.11.101's password:
Connection closed by 192.168.11.101 port 22
```
Наше правило сработало. Теперь все пользователи, кроме пользователей группы admin не могут зайти по ssh на хост.

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

##### 2.1 pam_groups.so

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
