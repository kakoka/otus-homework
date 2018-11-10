## Systemd

#### 1. Сервис, который который раз в 30 секунд мониторит лог.

Создадим службу с типом "notify" и таймер, который будет ее запускать с периодичностью в 30 секунд. Редактируем файлы:

```bash
$ nano /etc/sysconfig/monitor
$ nano monitor-timer.timer
$ nano monitor-timer.target
$ nano monitor-timer.service
```

Добавляем в `/etc/systemd/system` службу и таймер и активируем их:


```bash
$ sudo cp monitor-timer.* /etc/systemd/system/
$ sudo systemctl enable monitor-timer.timer
$ sudo systemctl enable monitor-timer.service
$ sudo systemctl start monitor-timer
```

Наблюдаем в логе сообщения:

```bash
$ sudo journalctl -f -u monitor-timer
```

<details>
  <summary>Лог</summary>
<pre>
Nov 10 12:46:30 otuslinux systemd[1]: Started SSH wrong username monitoring, run every 30 seconds.
Nov 10 12:46:30 otuslinux bash[24562]: Nov  9 20:09:41 otuslinux sshd[20213]: input_userauth_request: invalid user a [preauth]
Nov 10 12:46:30 otuslinux bash[24562]: Nov  9 20:09:43 otuslinux sshd[20218]: input_userauth_request: invalid user a [preauth]
Nov 10 12:46:30 otuslinux bash[24562]: Nov  9 20:09:45 otuslinux sshd[20220]: input_userauth_request: invalid user a [preauth]
Nov 10 12:46:30 otuslinux bash[24562]: Nov  9 20:09:45 otuslinux sshd[20222]: input_userauth_request: invalid user a [preauth]
</pre></details>
<br />

#### 2. Переписать init-скрипт на unit для spawn-fcgi.

```bash
$ yum -y install epel-release
$ yum -y install httpd.x86_64 spawn-fcgi php.x86_64
```
Делаем `cat /etc/init.d/spawn-fcgi`, смотрим на то, что в нем написано.

Юнит-файл будет типа `forking`, посколько нужно порождать и своевременно завершать процессы.
В `/etc/sysconfig/spawn-fcgi` опции запуска spawn-fcgi: количество процессов и тд. 

```bash
$ vi /etc/sysconfig/spawn-fcgi
$ vi /etc/systemd/system/spawn-fcgi.service
$ systemctl enable spawn-fcgi.service
$ systemctl start spawn-fcgi
```

<pre>
● spawn-fcgi.service - Start and stop FastCGI processes
   Loaded: loaded (/etc/systemd/system/spawn-fcgi.service; enabled; vendor preset: disabled)
   Active: active (running) since Sat 2018-11-10 19:53:20 UTC; 3s ago
  Process: 30397 ExecStart=/bin/spawn-fcgi $OPTIONS (code=exited, status=0/SUCCESS)
 Main PID: 30398 (php-cgi)
   CGroup: /system.slice/spawn-fcgi.service
           ├─30398 /usr/bin/php-cgi
           ├─30399 /usr/bin/php-cgi
           ├─30400 /usr/bin/php-cgi
           └─30401 /usr/bin/php-cgi
</pre>

##### 2.1 Небольшой troubleshooting.

Не сразу все завелось как нужно из-за прав, разрешений, наличия файлов и тд, `systemctl status spawn-fcgi.service` выдавал разные ошибки:

> Nov 10 19:09:07 otuslinux spawn-fcgi[29908]: spawn-fcgi: child exited with: 2 \
> Nov 10 19:09:07 otuslinux spawn-fcgi[29908]: spawn-fcgi: child exited with: 8 \
> Nov 10 19:09:07 otuslinux spawn-fcgi[29908]: spawn-fcgi: child exited with: 13

<details>
  <summary>Небольшой список кодов ошибок, которые использует Linux, когда знаешь их, понятно куда смотреть.</summary>
<pre>
#define EPERM        1  /* Operation not permitted */
#define ENOENT       2  /* No such file or directory */
#define ESRCH        3  /* No such process */
#define EINTR        4  /* Interrupted system call */
#define EIO          5  /* I/O error */
#define ENXIO        6  /* No such device or address */
#define E2BIG        7  /* Argument list too long */
#define ENOEXEC      8  /* Exec format error */
#define EBADF        9  /* Bad file number */
#define ECHILD      10  /* No child processes */
#define EAGAIN      11  /* Try again */
#define ENOMEM      12  /* Out of memory */
#define EACCES      13  /* Permission denied */
<pre></details>

#### 3. Дополнить юнит-файл apache httpd возможностью запустить несколько инстансов сервера с разными конфигурационными файлами

Дополнил файл `httpd@.service`:

>[Unit] \
> Description=Apache httpd server %I \
> ...
>[Service] \
> ExecStart=/usr/sbin/httpd $OPTIONS -f I% DFOREGROUND

Опция `-f %I` позволит добавлять разные файлы конфигурации в `/etc/httpd/conf`, например `node1`, `node2`, `node3` перед стартом httpd:

```bash
systemctl start httpd@node1.service
```

Можно так же делать это через `EnvironmentFile`, добавлять модификатор `%I` к нему, для достижения того же самого эффекта.

#### 4. Jira

