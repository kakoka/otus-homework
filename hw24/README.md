## MySQL InnoDB Cluster

### 1. DNS
### 2. MySQL nodes

grep mysqld /var/log/audit/audit.log | audit2allow -M mysqld
semodule -mysqld.pp

### 3. MySQL router

dba.configureInstance('cluster-user@192.168.50.101:3306', {clusterAdmin: "'cluster-user'@'node01'%", clusterAdminPassword: 'Cluster#1234!'});

### 3. Ссылки

- https://lefred.be/content/mysql-innodb-cluster-mysql-shell-starter-guide/
- https://www.soudegesu.com/en/mysql/mysql8-password/
- https://dev.mysql.com/doc/mysql-port-reference/en/mysql-ports-reference-tables.html
- https://linux.die.net/man/8/mysqld_selinux
- http://galeracluster.com/documentation-webpages/selinux.html
- https://relativkreativ.at/articles/how-to-compile-a-selinux-policy-package
- https://dev.mysql.com/doc/refman/8.0/en/mysql-innodb-cluster-working-with-cluster.html#use-mysql-shell-execute-script
- https://www.digitalocean.com/community/tutorials/how-to-configure-mysql-group-replication-on-ubuntu-16-04?comment=65995