# install ipa server and clients

ipa-server-install -U -r HOMEWORK.LOCAL -n homework.local -p 12345678 -a 12345678 --hostname=master --ip-address=192.168.11.150 --setup-dns --no-forwarders --no-reverse
ipa-client-install -U -p admin -w 12345678 --server=master.homework.local --ip-address=192.168.11.150 --domain=homework.local --realm=HOMEWORK.LOCAL --hostname=node1.homework.local --mkhomedir

# Add rule to grant sudo to users in admin group

ipa sudorule-add --cmdcat=all All
ipa sudorule-add-user --groups=admins All

# add user ssh-key

ipa user-add ololo --first=Ololo --last=PyshPysh --email=ololo@homework.local --shell=/bin/bash --sshpubkey="ssh-rsa AAA...o9"

ipa group-add-member admins --users=ololo

ipa user-mod ololo --sshpubkey="ssh-rsa AAA...6o9"