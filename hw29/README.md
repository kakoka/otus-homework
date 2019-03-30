## PostgreSQL cluster: etcd, HAproxy, patroni.

### Постановка задачи:

- развернуть кластер PostgreSQL из трех нод;
- cоздать тестовую базу, проверить статус репликации;
- cделать switchover/failover;
- поменять конфигурацию PostgreSQL, также сделать это с параметрами требующими
перезагрузки;
- настроить клиентские подключения через HAProxy.

Описание стенда:

Стенд состоит из 4 виртуальных машин: ns, pg01, pg02, pg03.

- ns.otus.test - сервисы NTP, DNS, HAproxy, etcd;
- pg01-pg03.otus.test - сервисы patroni, PostgreSQL11.

### 0. Подготовка

Для развертывания дополнительных сервисов написаны следующие роли:

- [NTP](provision/roles/ntp)
- [DNS](provision/roles/dns)
- [etcd](provision/roles/etcd)
- [HAproxy](provision/roles/haproxy)

NTP и DNS (взяты из [ДЗ №26](https://github.com/kakoka/otus-homework/tree/master/hw26)), в них внесены поправки:

- записи NS,A в файлах зон DNS сервера (pg01, pg02, pg03, ns);
- pg01-pg03 синхронизируют временя с ns.otus.test - изменение в конфигурации [NTP-client](provision/roles/ntp-client) `chronyd`.

Написаны [**ansible роли**](provision/roles) для всех компонентов стенда.

Etcd слушает на порту 2379:

```
ETCD_LISTEN_CLIENT_URLS="http://localhost:2379,http://<host_ip_addr_here>:2379"
```

HAproxy готов принимать подключения клиентов postgres на порт 5432. Заметим, что для лучшей балансировки нагрузки можно разделить backends в haproxy на 5432 read-write и 5433 read-only. Пример такой конфигурации ниже:

```
listen postgres *:5432
    option httpchk
    http-check expect status 200
    default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions
    server {{ host.name }} {{ host.name }}:5432 maxconn 100 check port 8008
    server {{ host.name }} {{ host.name }}:5432 maxconn 100 check port 8008    server {{ host.name }} {{ host.name }}:5432 maxconn 100 check port 8008
listen postgres_ro *:5433
    mode tcp
    balance roundrobin
    
    # expect: query result data
    #
    # "f" means node in master mode
    # "t" means node in standby mode (read-only)
    #
    tcp-check expect binary 44 # data row packet
    tcp-check expect binary 0000000b # packet lenght: 11 (0x0b)
    tcp-check expect binary 0001 # field count: 1
    tcp-check expect binary 00000001 # column length in bytes: 1
    tcp-check expect binary 66 # column data, "f"
    
    server {{ host.name }} {{ host.name }}:5432 check
    server {{ host.name }} {{ host.name }}:5432 check
```

Но поскольку мы работаем с кластером, который сообщает свое состояния в etcd и в зависимости от этого состояния выбирается primary, то конфигурация бэкенда будет другой, основанной на http-check, где код http со статусом 200 сообщает о том, какой сервер primary, и соответственно с ним и соединяются клиенты.

<pre>
    http-check expect status 200
    default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions
</pre>

### 1. Patroni

Для развертывания кластера PostgeSQL на каждую ноду необходимо установить potgres, patroni, и зависимости для их работы. Для каждой ноды генерируется файл настройки `/etc/patroni.yml` с помощью шаблона ansible роли. В шаблоне определены настройки, с которыми будет запущен postgres на каждой ноде:

```yaml
bootstrap:
...
initdb:
  - encoding: UTF8
  - data-checksums

  pg_hba:
  - host replication replication 127.0.0.1/32 md5
  {% for pg_host in pg_hosts %}
  - host replication replication {{ pg_host.ip }}/0 md5
  {% endfor %}
  - host all all 0.0.0.0/0 md5

  users:
    admin:
      password: admin
      options:
        - createrole
        - createdb
...
postgresql:
  listen: {{ host.ip }}:5432
  bin_dir: {{ pg_bin_dir }}
  connect_address: {{ host.ip }}:5432
  data_dir: {{ pg_database_dir }}
  pgpass: /tmp/pgpass
  authentication:
    replication:
      username: replication
      password: replication
    superuser:
      username: postgres
      password: postgres
```

Определены переменные, которые подставляются в шаблон:


```yaml
etcd_hosts: 
  - { name: 'ns.otus.test', ip: '192.168.50.10' }
pg_hosts:
  - { name: 'pg01.otus.test', ip: '192.168.50.101', alias: 'pg01' }
  - { name: 'pg02.otus.test', ip: '192.168.50.102', alias: 'pg02' }
  - { name: 'pg03.otus.test', ip: '192.168.50.103', alias: 'pg03' }

pg_bin_dir: /usr/pgsql-11/bin
pg_database_dir: /var/lib/pgsql/11/data
```

### 2. Использование стенда

После клонирования репозитория:

<pre>
$ vagrant up
$ vagrant ssh pg01
</pre>

Через провижн при старте ВМ происходит создание кластера.

Командной `sudo patronictl -c /etc/patroni.yml list` можно посмотреть статус кластера и кто лидер.

<pre>
+---------+--------+----------------+--------+---------+----+-----------+
| Cluster | Member |      Host      |  Role  |  State  | TL | Lag in MB |
+---------+--------+----------------+--------+---------+----+-----------+
|   otus  |  pg01  | 192.168.50.101 | Leader | running |  1 |       0.0 |
|   otus  |  pg02  | 192.168.50.102 |        | running |  1 |       0.0 |
|   otus  |  pg03  | 192.168.50.103 |        | running |  1 |       0.0 |
+---------+--------+----------------+--------+---------+----+-----------+
</pre>

### 3. Подключения через HAproxy, создание тестовой базы, проверка статуса репликации, switchover/failover

С витруальной машины ns.otus.test на хост систему проброшены порты 5432, 7000. В кластере три ноды, одна primary - pg01.otus.tes, а остальные - реплики hot_stanby: pg02-pg03.otus.test, доступные только для чтения. Для того, что бы была возможность писать в базу haproxy проверяет ноды, на которых установлен patroni. Ноды сообщают свой статус (см. табличку выше), соединение происходит с той, которая `Leader` c возможностью писать в базу:

Подключимся c локалхоста к серверу postgres через ns.otus.test, создадим базу данных `test`, подключимся к ней, создадим таблицу `testtable` и добавим в нее данные:

```sql
$ psql "postgres://postgres:postgres@localhost:5432/postgres"
postgres=# create database test;
postgres=# \c test
test=# create table testtable(id serial primary key, name varchar(50));
test=# insert into testtable values (1,'pasha'),(2,'vasya'),(3,'petya');
test=# select * from testtable;
```

Выключаем `pg01` - `vagrant halt pg01`. На скриншоте видно, что pg02.otus.test начинает промоутится до primary.

![](pic/pic01.png)

И проверяем, сделаем запрос на выборку не выходя из клиента `psql`:

```bash
test=# select * from testtable;
```

![](pic/pic02.png)

И убеждаемся, что в данной конфигурации переключение на нового primary происходит автоматически (можно это делать и вручную, patronictl switchover <cluster name>, если нам, например, нужно что-то сделать с нодой). На скриншоте видно, что pg02 теперь primary.

![](pic/pic03.png)

### 5. Изменения конфигурации PostgreSQL, требующие рестарта

Внесем в изменения в конфигурацию постгреса:

```yml
parameters:
  shared_preload_libraries: 'pg_stat_statements'
  max_wal_senders: '10'
  shared_buffers: '128MB'
  work_mem: '8MB'
```

Делаем рестарт кластера с новыми параметрами `patronictl -c /etc/patroni.yml restart otus`:

<pre>
[root@pg01 vagrant]# patronictl -c /etc/patroni.yml restart otus
+---------+--------+----------------+--------+---------+----+-----------+
| Cluster | Member |      Host      |  Role  |  State  | TL | Lag in MB |
+---------+--------+----------------+--------+---------+----+-----------+
|   otus  |  pg01  | 192.168.50.101 |        | running |  4 |       0.0 |
|   otus  |  pg02  | 192.168.50.102 | Leader | running |  4 |       0.0 |
|   otus  |  pg03  | 192.168.50.103 |        | running |  4 |       0.0 |
+---------+--------+----------------+--------+---------+----+-----------+
Are you sure you want to restart members pg01, pg02, pg03? [y/N]: y
Restart if the PostgreSQL version is less than provided (e.g. 9.5.2)  []:
When should the restart take place (e.g. 2015-10-01T14:30)  [now]:
Success: restart on member pg01
Success: restart on member pg02
Success: restart on member pg03
</pre>

### 6. Ссылки

- https://blog.dbi-services.com/using-ansible-to-bring-up-a-three-node-patroni-cluster-in-minutes/
- https://www.linode.com/docs/databases/postgresql/create-a-highly-available-postgresql-cluster-using-patroni-and-haproxy/
- https://pgconf.ru/2019/242817
- https://habr.com/ru/post/322036/
- https://ru.bmstu.wiki/PostgreSQL_%D0%BD%D0%B0_%D0%B1%D0%B0%D0%B7%D0%B5_Patroni,_HAProxy_%D0%B8_Keepalived
- https://patroni.readthedocs.io/en/latest/dynamic_configuration.html