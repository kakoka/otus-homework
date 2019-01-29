## DNS

### 1. Split-dns

В Vagrantfile добавим сервер `client2`, в dns-зону [`dns.lab`](provisioning/named.dns.lab) добавим записи:

<pre>
web1            IN      A       192.168.50.15
web2            IN      A       192.168.50.16
</pre> 

Создадим dns-зону [newdns.lab](provisioning/named.newdns.lab)
и добавим запись `www`:

<pre>
newdns.lab.     IN      A       192.168.50.15
newdns.lab.     IN      A       192.168.50.16
www             IN      CNAME   newdns.lab.
</pre>

Добавим указание на загрузку зоны демоном `named` в [named.conf](provisioning/master-named.conf).

#### 1.1 `Client` видит зоны dns.lab и newdns.lab, в зоне dns.lab видит только web1.dns.lab.

Для реализации split-dns применим следующие директивы в конфигурационном файле [named.conf](provisioning/master-named.conf):

- `view` - ограничивает выдачу ответов от dns сервера в соответсвие с указанными внутри параметрами и перечисленными зонами;
	- `match-clients` - выбираем вид в зависимости от адреса клиента 
	- `allow-query` - разрешаем клиенту запросы к dns
- `acl` - определяет списки доступа клиентов к dns серверу.


Комбинация view и acl позволяет гибко настроить требуемые параметры для split-dns. Для `client` создадим отдельный файл зоны [`dns.lab`](provisioning/named.client.dns.lab) куда запишем только `web1.dns.lab`:

<pre>
acl web1 { 192.168.50.15; };
...
view "web1" {
    match-clients { web1; };
    recursion yes;
    allow-query { web1; };
        
    zone "dns.lab" { 
    ...
    file "/etc/named/named.newdns.lab";
    };
    zone "newdns.lab" { ... };
...
};
</pre>

Другие зоны: [dns.lab](provisioning/named.dns.lab), [dns.lab.rev](provisioning/named.dns.lab.rev), [ddns.lab](provisioning/named.ddns.lab), [newdns.lab](provisioning/named.newdns.lab). Не стал делать реверс-зоны для всех зон (dns сервер умеет их сам генерировать, если что).

Проверяем:

<pre>
[vagrant@client ~]$ ping web1.dns.lab
PING web1.dns.lab (192.168.50.15) 56(84) bytes of data.
64 bytes from web1.dns.lab (192.168.50.15): icmp_seq=1 ttl=64 time=0.010 ms
</pre>

<pre>
[vagrant@client ~]$ ping web2.dns.lab
ping: web2.dns.lab: Name or service not known
</pre>

<pre>
[vagrant@client ~]$ ping www.newdns.lab
PING newdns.lab (192.168.50.15) 56(84) bytes of data.
64 bytes from web1.dns.lab (192.168.50.15): icmp_seq=1 ttl=64 time=0.014 ms
</pre>

<details>
<summary>[vagrant@client ~]$ dig any web1.dns.lab</summary>
<pre>
; <<>> DiG 9.9.4-RedHat-9.9.4-72.el7 <<>> any web1.dns.lab
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 27222
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 2, ADDITIONAL: 3

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;web1.dns.lab.			IN	ANY

;; ANSWER SECTION:
web1.dns.lab.		3600	IN	A	192.168.50.15

;; AUTHORITY SECTION:
dns.lab.		3600	IN	NS	ns01.dns.lab.
dns.lab.		3600	IN	NS	ns02.dns.lab.

;; ADDITIONAL SECTION:
ns01.dns.lab.		3600	IN	A	192.168.50.10
ns02.dns.lab.		3600	IN	A	192.168.50.11

;; Query time: 0 msec
;; SERVER: 192.168.50.10#53(192.168.50.10)
;; WHEN: Tue Jan 29 21:16:31 UTC 2019
;; MSG SIZE  rcvd: 127
</pre></details>

<details>
<summary>[vagrant@client ~]$ dig any web2.dns.lab</summary>
<pre>
; <<>> DiG 9.9.4-RedHat-9.9.4-72.el7 <<>> any web2.dns.lab
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 27785
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;web2.dns.lab.			IN	ANY

;; AUTHORITY SECTION:
dns.lab.		600	IN	SOA	ns01.dns.lab. root.dns.lab. 2901201901 3600 600 86400 600

;; Query time: 0 msec
;; SERVER: 192.168.50.10#53(192.168.50.10)
;; WHEN: Tue Jan 29 21:17:13 UTC 2019
;; MSG SIZE  rcvd: 87
</pre></details>

<details>
<summary>[vagrant@client ~]$ dig any www.newdns.lab</summary>
<pre>
; <<>> DiG 9.9.4-RedHat-9.9.4-72.el7 <<>> any www.newdns.lab
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 11448
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 2, ADDITIONAL: 3

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;www.newdns.lab.			IN	ANY

;; ANSWER SECTION:
www.newdns.lab.		3600	IN	CNAME	newdns.lab.

;; AUTHORITY SECTION:
newdns.lab.		3600	IN	NS	ns01.newdns.lab.
newdns.lab.		3600	IN	NS	ns02.newdns.lab.

;; ADDITIONAL SECTION:
ns01.newdns.lab.	3600	IN	A	192.168.50.10
ns02.newdns.lab.	3600	IN	A	192.168.50.11

;; Query time: 0 msec
;; SERVER: 192.168.50.10#53(192.168.50.10)
;; WHEN: Tue Jan 29 21:21:06 UTC 2019
;; MSG SIZE  rcvd: 127
</pre>
</details>

#### 1.2 `Client2` видит только dns-зону dns.lab.

Ограничиваем видимость для этого клиента с помощью `view`:

<pre>
acl web2 { 192.168.50.16; };
...
view "web2" {
        match-clients { web2; };
        allow-query { web2; };

        zone "dns.lab" { ... };
        zone "50.168.192.in-addr.arpa" { ... };
};
</pre>

Проверяем:

<pre>
[vagrant@client2 ~]$ ping www.dns.lab
ping: www.dns.lab: Name or service not known
</pre>

<pre>
[vagrant@client2 ~]$ ping web1.dns.lab
PING web1.dns.lab (192.168.50.15) 56(84) bytes of data.
64 bytes from web1.dns.lab (192.168.50.15): icmp_seq=1 ttl=64 time=0.349 ms
</pre>

<pre>
[vagrant@client2 ~]$ ping web2.dns.lab
PING web2.dns.lab (192.168.50.16) 56(84) bytes of data.
64 bytes from web2.dns.lab (192.168.50.16): icmp_seq=1 ttl=64 time=0.018 ms
</pre>

<details>
<summary>[vagrant@client2 ~]$ dig any www.newdns.lab</summary>
<pre>
; <<>> DiG 9.9.4-RedHat-9.9.4-72.el7 <<>> any www.newdns.lab
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 9104
;; flags: qr rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;www.newdns.lab.			IN	ANY

;; AUTHORITY SECTION:
.			10800	IN	SOA	a.root-servers.net. nstld.verisign-grs.com. 2019012901 1800 900 604800 86400

;; Query time: 16 msec
;; SERVER: 192.168.50.10#53(192.168.50.10)
;; WHEN: Tue Jan 29 21:26:37 UTC 2019
;; MSG SIZE  rcvd: 118
</pre>
</details>

<details>
<summary>[vagrant@client2 ~]$ dig any web1.dns.lab</summary>
<pre>
; <<>> DiG 9.9.4-RedHat-9.9.4-72.el7 <<>> any web1.dns.lab
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 38569
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 2, ADDITIONAL: 3

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;web1.dns.lab.			IN	ANY

;; ANSWER SECTION:
web1.dns.lab.		3600	IN	A	192.168.50.15

;; AUTHORITY SECTION:
dns.lab.		3600	IN	NS	ns01.dns.lab.
dns.lab.		3600	IN	NS	ns02.dns.lab.

;; ADDITIONAL SECTION:
ns01.dns.lab.		3600	IN	A	192.168.50.10
ns02.dns.lab.		3600	IN	A	192.168.50.11

;; Query time: 0 msec
;; SERVER: 192.168.50.10#53(192.168.50.10)
;; WHEN: Tue Jan 29 21:25:06 UTC 2019
;; MSG SIZE  rcvd: 127
</pre>
</details>

<details>
<summary>[vagrant@client2 ~]$ dig any web2.dns.lab</summary>
<pre>
; <<>> DiG 9.9.4-RedHat-9.9.4-72.el7 <<>> any web2.dns.lab
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 47639
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 2, ADDITIONAL: 3

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;web2.dns.lab.			IN	ANY

;; ANSWER SECTION:
web2.dns.lab.		3600	IN	A	192.168.50.16

;; AUTHORITY SECTION:
dns.lab.		3600	IN	NS	ns02.dns.lab.
dns.lab.		3600	IN	NS	ns01.dns.lab.

;; ADDITIONAL SECTION:
ns01.dns.lab.		3600	IN	A	192.168.50.10
ns02.dns.lab.		3600	IN	A	192.168.50.11

;; Query time: 0 msec
;; SERVER: 192.168.50.10#53(192.168.50.10)
;; WHEN: Tue Jan 29 21:25:57 UTC 2019
;; MSG SIZE  rcvd: 127
</pre>
</details>


### 2. Настроить dns, ddns без выключения selinux

Проверим контекст безопасности в директориях, куда bind записывает свои конфигурационные файлы по умолчанию - `/var/named` и установим этот контекст через провижн ansible для директории и файлов `/etc/named`:

<pre>
$ semanage fcontext -l | grep '/var/named'

/var/named/chroot/var/named(/.*)?                  all files          system_u:object_r:named_zone_t:s0
</pre>

Видим, что это контекст `named_zone_t`. Создаем три задачи: 

- установим контекст,
- применим его,
- включим SELinux.

<pre>
  - name: SElinux fix for /etc/named
    sefcontext:
      target: "/etc/named(/.*)?"
      setype: named_zone_t
      state: present
  - name: Apply new SELinux file context to filesystem
    command: restorecon -R -v /etc/named
  - name: Enable SELinux
    selinux:
      policy: targeted
      state: enforcing    
</pre>

Проверяем, с `client` добавляем записи в зону `ddns.lab`:

<pre>
[vagrant@client ~]$ nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
>
</pre>

<pre>
[vagrant@client ~]$ ping www.ddns.lab
PING www.ddns.lab (192.168.50.15) 56(84) bytes of data.
64 bytes from web1.dns.lab (192.168.50.15): icmp_seq=1 ttl=64 time=0.021 ms
</pre>

### 3. Ссылки

- http://mx54.ru/nastrojka-dns-bind-razdelenie-cherez-view/
- https://docs.ansible.com/ansible/latest/modules/selinux_module.html