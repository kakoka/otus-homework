## Systemd

#### 0. Установим epel

yum -y install epel-release

#### 1. Таймер

Создаем и редактируем файлы:

```bash
$ nano /etc/sysconfig/monitor
$ nano monitor
$ nano monitor-timer.timer
$ nano monitor-timer.target
$ nano monitor-timer.service
```

Добавляем и активируем службу и таймер:


```bash
sudo cp monitor /usr/sbin
sudo chmod +x /usr/sbin/monitor
sudo cp monitor-timer.* /etc/systemd/system/
sudo systemctl enable monitor-timer.timer
sudo systemctl enable monitor-timer.service
sudo systemctl start monitor-timer.service
```

Наблюдаем в логе сообщения:

```bash
$ sudo journalctl -f -u monitor-timer
```

<details>
  <summary>Лог</summary>
<pre>
Nov 09 14:25:04 otuslinux systemd[1]: Started SSH wrong username montitoring, run        every 30 seconds.
Nov 09 14:25:04 otuslinux systemd[1]: Starting SSH wrong username montitoring, run        every 30 seconds...
Nov 09 14:25:04 otuslinux systemd[1]: monitor-timer.service: main process exited, code=exited, status=203/EXEC
Nov 09 14:25:04 otuslinux systemd[1]: Unit monitor-timer.service entered failed state.
Nov 09 14:25:04 otuslinux systemd[1]: monitor-timer.service failed.
Nov 09 14:26:58 otuslinux systemd[1]: Started SSH wrong username montitoring, run        every 30 seconds.
Nov 09 14:26:58 otuslinux systemd[1]: Starting SSH wrong username montitoring, run        every 30 seconds...
Nov 09 14:26:58 otuslinux monitor[18753]: Nov  9 12:34:09 otuslinux sshd[17997]: input_userauth_request: invalid user sfd [preauth]
Nov 09 14:26:58 otuslinux monitor[18753]: Nov  9 12:34:57 otuslinux sshd[17999]: input_userauth_request: invalid user sfd [preauth]
Nov 09 14:26:58 otuslinux monitor[18753]: Nov  9 14:01:41 otuslinux sshd[18414]: input_userauth_request: invalid user aaaa [preauth]
</pre></details>
<br />

#### 2. Второй


