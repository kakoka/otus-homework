## VPN
### Между двумя виртуальными машинами поднять vpn в разных режимах

#### tun

Client1.area1 - openvpn server
Client3.area3 - openvpn client

**server**
Client1.area1 - openvpn server

/etc/openvpn/server/server.conf

```
dev tun
ifconfig 10.10.8.1 10.10.8.2
secret static.key
```

```
$ systemctl enable openvpn-server@server.service
$ systemctl start openvpn-server@server
```

```
$ cat /run/openvpn-server/status-server.log
OpenVPN STATISTICS
Updated,Wed Jan 23 19:50:44 2019
TUN/TAP read bytes,144
TUN/TAP write bytes,288
TCP/UDP read bytes,672
TCP/UDP write bytes,376
Auth read bytes,322
END
```

**client**
Client3.area3 - openvpn client

/etc/openvpn/client/client.conf

```
dev tun
remote client1.area1
ifconfig 10.10.8.2 10.10.8.1
secret static.key
```

```
$ systemctl enable openvpn-client@client.service
$ systemctl start openvpn-client@client
$ journalctl -u openvpn-client@client
```

```
Jan 23 19:36:20 Client3 systemd[1]: Started OpenVPN tunnel for client.
Jan 23 19:36:20 Client3 openvpn[6023]: TUN/TAP device tun0 opened
Jan 23 19:36:20 Client3 openvpn[6023]: do_ifconfig, tt->did_ifconfig_ipv6_setup=0
Jan 23 19:36:20 Client3 openvpn[6023]: /sbin/ip link set dev tun0 up mtu 1500
Jan 23 19:36:20 Client3 openvpn[6023]: /sbin/ip addr add dev tun0 local 10.10.8.2 peer 10.10.8.1
Jan 23 19:36:20 Client3 openvpn[6023]: TCP/UDP: Preserving recently used remote address: [AF_INET]10.10.1.2:1194
Jan 23 19:36:20 Client3 openvpn[6023]: UDP link local: (not bound)
Jan 23 19:36:20 Client3 openvpn[6023]: UDP link remote: [AF_INET]10.10.1.2:1194
Jan 23 19:36:31 Client3 openvpn[6023]: Peer Connection Initiated with [AF_INET]10.10.1.2:1194
Jan 23 19:36:32 Client3 openvpn[6023]: WARNING: this configuration may cache passwords in memory -- use the auth-nocache option to prevent this
Jan 23 19:36:32 Client3 openvpn[6023]: Initialization Sequence Completed
```

<pre> tracepath 10.10.8.1
 1?: [LOCALHOST]                                         pmtu 1500
 1:  10.10.8.1                                             1.621ms reached
 1:  10.10.8.1                                             1.637ms reached
     Resume: pmtu 1500 hops 1 back 1
</pre>

<pre>ping 10.10.8.1
PING 10.10.8.1 (10.10.8.1) 56(84) bytes of data.
64 bytes from 10.10.8.1: icmp_seq=1 ttl=64 time=1.71 ms
64 bytes from 10.10.8.1: icmp_seq=2 ttl=64 time=1.93 ms
64 bytes from 10.10.8.1: icmp_seq=3 ttl=64 time=1.80 ms
64 bytes from 10.10.8.1: icmp_seq=4 ttl=64 time=1.30 ms
</pre>

<pre>
[user@Router3 ~]# tcpdump -i eth2
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on eth2, link-type EN10MB (Ethernet), capture size 262144 bytes
19:57:25.665679 IP router3-eth2 > ospf-all.mcast.net: OSPFv2, Hello, length 44
19:57:32.088940 IP client1.area3.34456 > client1.area1.openvpn: UDP, bad length 1540 > 1472
19:57:32.089297 IP client1.area3 > client1.area1: udp
19:57:32.091708 IP client1.area1.openvpn > client1.area3.34456: UDP, length 620
19:57:32.417291 IP client1.area3.34456 > client1.area1.openvpn: UDP, bad length 1540 > 1472
19:57:32.417385 IP client1.area3 > client1.area1: udp
19:57:32.418601 IP client1.area1.openvpn > client1.area3.34456: UDP, length 620
19:57:35.666735 IP router3-eth2 > ospf-all.mcast.net: OSPFv2, Hello, length 44
19:57:37.100015 ARP, Request who-has client1.area3 tell router3-eth2, length 28
19:57:37.100410 ARP, Reply client1.area3 is-at 08:00:27:21:12:bb (oui Unknown), length 46
19:57:45.668710 IP router3-eth2 > ospf-all.mcast.net: OSPFv2, Hello, length 44
19:57:49.014243 IP client1.area3.34456 > client1.area1.openvpn: UDP, length 124
19:57:49.015272 IP client1.area1.openvpn > client1.area3.34456: UDP, length 124
19:57:50.016364 IP client1.area3.34456 > client1.area1.openvpn: UDP, length 124
19:57:50.017537 IP client1.area1.openvpn > client1.area3.34456: UDP, length 124
19:57:51.019031 IP client1.area3.34456 > client1.area1.openvpn: UDP, length 124
19:57:51.020044 IP client1.area1.openvpn > client1.area3.34456: UDP, length 124
19:57:52.021065 IP client1.area3.34456 > client1.area1.openvpn: UDP, length 124
19:57:52.021904 IP client1.area1.openvpn > client1.area3.34456: UDP, length 124
19:57:54.032505 ARP, Request who-has router3-eth2 tell client1.area3, length 46
19:57:54.032533 ARP, Reply router3-eth2 is-at 08:00:27:fa:4a:3e (oui Unknown), length 28
19:57:55.670782 IP router3-eth2 > ospf-all.mcast.net: OSPFv2, Hello, length 44
</pre>

#### tap

Client1.area1 - openvpn server
Client3.area3 - openvpn client

<pre>
dev tap
ifconfig 10.10.8.1 255.255.255.0
topology subnet
secret static.key
status /var/run/openvpn-status.log
log /var/log/openvpn.log
verb 3
</pre>


remote client1.area1

#### Прочуствовать разницу.

### 2. Поднять RAS на базе OpenVPN с клиентскими сертификатами, подключиться с локальной машины на виртуалку

#OSPF
https://superuser.com/questions/1283125/proper-configuration-for-quagga-ospf-on-an-openvpn-network

https://habr.com/ru/post/233971/
https://github.com/cloudflare/cfssl
http://swaj.net/zametki/openvpn.html


### 3. поднять ocserv и подключиться с хоста к виртуалке