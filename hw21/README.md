## DNS
### Split-dns

добавить еще один сервер client2

### завести в зоне dns.lab 

имена
web1 - смотрит на клиент1
web2 - смотрит на клиент2

### завести еще одну зону newdns.lab

завести в ней запись
www - смотрит на обоих клиентов

### настроить split-dns

клиент1 - видит обе зоны, но в зоне dns.lab только web1

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
ping www.newdns.lab
PING newdns.lab (192.168.50.15) 56(84) bytes of data.
64 bytes from web1.dns.lab (192.168.50.15): icmp_seq=1 ttl=64 time=0.014 ms
</pre>

клиент2 видит только dns.lab

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

### настроить все без выключения selinux

ddns тоже должен работать без выключения selinux

`semanage fcontext -l | grep '/etc/named'`

<pre>
  - name: SElinux fix for /etc/named
    sefcontext:
      target: "/etc/named(/.*)?"
      setype: named_zone_t
      state: present
  - name: Apply new SELinux file context to filesystem
    command: restorecon -R -v /etc/named
</pre>

http://mx54.ru/nastrojka-dns-bind-razdelenie-cherez-view/
