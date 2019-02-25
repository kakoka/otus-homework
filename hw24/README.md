## MYSQL

### 1. Ansible

\connect cluster-user:'Cluster#1234!'@node01:3306

dba.configureInstance('cluster-user@192.168.50.101:3306', {clusterAdmin: "'cluster-user'@'node01'%", clusterAdminPassword: 'Cluster#1234!'});

mysql -u cluster-user -p'Cluster#1234!' -h node01
### 3. Ссылки

- https://www.soudegesu.com/en/mysql/mysql8-password/
- 