## PAM

#### 1. Запретить всем пользователям, кроме группы admin логин в выходные и праздничные дни

Создадим группу `myusers` и добавим в нее пользователей vasya, petya и kolya:
 
```bash
$ groupadd myusers
$ useradd -g myusers vasya
$ useradd -g myusers petya
$ useradd -g myusers kolya
```

Добавим правило в /etc/security/time.conf:

```bash
sshd;*;!vagrant;!Wk0000-2400
```

Добавим правило в /etc/pam.d/system-auth

```bash
account required pam_time.so
```

Пробуем зайти по ssh:

```bash
$ ssh petya@192.168.11.101

petya@192.168.11.101's password:
Connection closed by 192.168.11.101 port 22

```
Наше правило сработало. Теперь все пользователи, кроме пользователя vagrnat не могут зайти по ssh на хост.
