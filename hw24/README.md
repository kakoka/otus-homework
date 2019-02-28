## MYSQL

### 1. Ansible

echo 'Cluster#1234!' | mysqlsh --uri cluster-admin@node03 -e "dba.getCluster().addInstance({user: "cluster-admin", host: "node02", password: 'Cluster#1234!'});" --passwords-from-stdin

!!! dba.configureInstance('cluster-user@node01:3306', {clusterAdmin: "cadmin", clusterAdminPassword: "pa$sworD123"});

\connect cluster-user:'Cluster#1234!'@node01:3306

dba.configureInstance('cluster-user@192.168.50.101:3306', {clusterAdmin: "'cluster-user'@'node01'%", clusterAdminPassword: 'Cluster#1234!'});

mysql -u cluster-user -p'Cluster#1234!' -h node01
### 3. Ссылки

- https://www.soudegesu.com/en/mysql/mysql8-password/
- 


mysqlsh --uri cluster-admin@node02 -e "dba.createCluster('clTest');"


grep mysqld /var/log/audit/audit.log | audit2allow -M mysqld
semodule -mysqld.pp