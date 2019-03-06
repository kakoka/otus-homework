yum install krb5-workstation ntpdate ntp

yum install sssd realmd oddjob oddjob-mkhomedir adcli samba samba-common samba-common-tools sssd-libwbclient

yum install policycoreutils-python samba-client samba-common samba-common-tools sssd-libwbclient

ntpdate buhg.local

yum install samba samba-client samba-common
yum install krb5-workstation samba-common-tools sssd-ad




realm join --user=Administrator buhg.local
realm list
authconfig --update --enablesssd --enablesssdauth --enablemkhomedir

kinit Administrator
net ads keytab create -UAdministrator
klist -k
klist -c /var/lib/sss/db/ccache_BUHG.LOCAL

> ktutil
  ktutil:  addent -password -p administrator@DOMAIN -k 1 -e rc4-hmac
  Password for administrator@DOMAIN: [enter your password]
  ktutil:  addent -password -p administrator@DOMAIN -k 1 -e aes256-cts
  Password for administrator@DOMAIN: [enter your password]
  ktutil:  wkt krb5.keytab
  ktutil:  quit


testparm


I can use "net rpc getsid" to set the domain SID into samba's secrets.tdb, without knowing it beforehand

net rpc getsid -UAdministrator


getent group "BUHG\\Domain Users"

net rpc rights grant 'BUHG\Domain Admins' SeDiskOperatorPrivilege -Uadministrator

chcon -t samba_share_t /home/kakoka/git/otus-homework/
chown administrator:'domain users' /home/kakoka/git/otus-homework
chmod 0750 /home/kakoka/git/otus-homework
getfacl /home/kakoka/git/otus-homework/
setfacl -m d:g:'domain users':rwx /home/kakoka/git/otus-homework
smbpasswd -a kakoka

- https://kb.iu.edu/d/aumh
- https://wiki.samba.org/index.php/Samba_Member_Server_Troubleshooting
- https://runops.wordpress.com/2015/04/22/create-machine-keytab-on-linux-for-active-directory-authentication/
- https://jimshaver.net/2016/05/30/setting-up-an-active-directory-domain-controller-using-samba-4-on-ubuntu-16-04/
- https://www.thegeekdiary.com/how-to-add-or-delete-a-samba-user-under-linux/
- https://lists.samba.org/archive/samba/2017-February/206616.html
- http://koo.fi/blog/2015/06/16/ubuntu-14-04-active-directory-authentication/
- https://www.altlinux.org/%D0%A1%D0%BE%D0%B7%D0%B4%D0%B0%D0%BD%D0%B8%D0%B5_SPN_%D0%B8_Keytab_%D1%84%D0%B0%D0%B9%D0%BB%D0%B0
- https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/deployment_guide/s1-checking_the_status_of_ntp

- https://www.certdepot.net/rhel7-configure-kerberos-kdc/
- https://ping.force.com/Support/servlet/fileField?retURL=%2FSupport%2Fapex%2FPingIdentityArticle%3Fid%3DkA3400000008RZLCA2&entityId=ka3400000008XOTAA2&field=Associated_File__Body__s