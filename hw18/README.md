## VLAN. Bonding.

### 1. VLAN


```
NM_CONTROLED=no
BOOTPROTO=none
VLAN=yes
ONBOOT=yes
IPADDR=10.10.10.1
NETMASK=255.255.255.0
DEVICE=eth1.1
```

/etc/sysconfig/network-scripts/ifcfg-eth1.1


### 2. Bonding

С обеих сторон inetRouter - centralRouter

```
NM_CONTROLED=no
DEVICE=bond0
ONBOOT=yes
TYPE=Bond
BONDING_MASTER=yes
IPADDR=192.168.255.1
PREFIX=30
BOOTPROTO=static
BONDING_OPTS="mode=1 miimon=100 fail_over_mac=1"
```

/etc/sysconfig/network-scripts/ifcfg-bond0

```
NM_CONTROLED=no
BOOTPROTO=none
ONBOOT=yes
DEVICE=eth1
MASTER=bond0
SLAVE=yes 
```

/etc/sysconfig/network-scripts/ifcfg-eth1

```
NM_CONTROLED=no
BOOTPROTO=none
ONBOOT=yes
DEVICE=eth2
MASTER=bond0
SLAVE=yes
```

/etc/sysconfig/network-scripts/ifcfg-eth2
