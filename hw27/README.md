## Postfix, Dovecot


1. Установить postfix+dovecot для приёма почты на виртуальный домен
2. Отправить почту телнетом с хоста на виртуалку
3. Принять почту на хост почтовым клиентом

Результат
1. Полученное письмо со всеми заголовками
2. Конфиги postfix и dovecot

`
echo "qq" | mailx -s "test" -r "<vagrant@otus.test>" vagrant@otus.test
echo "qq" | mailx -s "test" -r "<dovecot@otus.test>" vagrant@otus.test
`

<pre>
[root@client ~]# telnet ns 143
Trying 192.168.50.10...
Connected to ns.
Escape character is '^]'.
* OK [CAPABILITY IMAP4rev1 LITERAL+ SASL-IR LOGIN-REFERRALS ID ENABLE IDLE AUTH=PLAIN] Dovecot ready.
a login vagrant vagrant
</pre>

### 1. DNS, NTP

Конфигурацию DNS сервера и файлы зоны возьмем из [21 домашнего задания](https://github.com/kakoka/otus-homework/tree/master/hw21). Модифицируем настройки исходя из конфигурации нашего стенда - домен `otus.test`, напишем [роль](provision/roles/dns) развертывания DNS сервера. Внесем изменения в [`/etc/resolv.conf`](provision/roles/dns/files/resolv.conf) на клиенте и на сервере.

Настроим штатный сервис синхронизации времени для Centos/7 - `chronyd` как локальный сервер NTP. Сервер будет синхронизироваться с одним из серверов из пула `0.rhel.pool.ntp.org`, клиент будет синхронизироваться уже с нашим сервером. Роли для [сервера](provision/roles/ntp) и для [клиента](provision/roles/ntp-client).

Конфигурация сервера:
<pre>
server 0.centos.pool.ntp.org iburst
manual
allow 192.168.0.0/16
local stratum 8
</pre>

Конфигурация клиента:
<pre>
server ns.otus.test iburst
driftfile /var/lib/chrony/drift
logdir /var/log/chrony
log measurements statistics tracking
</pre>

Соответствующие роли: [сервер](provision/roles/ntp), [клиент](provision/roles/ntp-client).

### 2. Postfix

### 3. Dovecot

### 3. DKIM

### 4. Firewalld

Для корректной работы в сети NFS сервера с использованием Kerberos требуется открыть порты для сервисов:

- SSH (22/tcp)
- NTP (123/udp)
- DNS (53/tcp, 53/udp)
- Kerberos (88/tcp, 88/udp, 794/tcp - см. файл [kerberos.xml](provision/roles/firewall/files/kerberos.xml)) 
- NFS (111/tcp, 111/upd - rpc-bind, 2049/tcp, 2049/udp - nfs сервер)

<pre>
firewall-cmd --permanent --add-service=rpc-bind
firewall-cmd --permanent --add-service=mountd
firewall-cmd --permanent --add-port=2049/tcp
firewall-cmd --permanent --add-port=2049/udp
firewall-cmd --reload
</pre>

Добавим их в правила файерволла, написана соответствующая [роль](provision/roles/firewall).

### 5. Использование стенда

После клонирования репозитория, `vagrant up`, `vagrant ssh client`.

### 6. Ссылки

- https://habr.com/ru/company/ruvds/blog/325356/
- https://support.rackspace.com/how-to/dovecot-installation-and-configuration-on-centos/
- https://rimuhosting.com/support/bindviawebmin.jsp#dns
- https://blog.bissquit.com/unix/debian/bazovaya-nastrojka-postfix-i-dovecot/
- http://snakeproject.ru/rubric/article.php?art=freebsd_postfix_dovecot_dkim_09.2018
- http://www.shakthimaan.com/installs/alpine-email-setup.html
- https://docs.gitlab.com/ee/administration/reply_by_email_postfix_setup.html