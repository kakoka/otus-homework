## PostgreSQL

- Настроить hot_standby репликацию с использованием слотов
- Настроить правильное резервное копирование

Для сдачи присылаем postgresql.conf, pg_hba.conf и recovery.conf
А так же конфиг barman, либо скрипт резервного копирования

### Репликация

#### 1. primary

psql -c "CREATE USER replication REPLICATION LOGIN CONNECTION LIMIT 1 ENCRYPTED PASSWORD 'swimming3';"
createuser --replication -P replication
psql -c "ALTER ROLE replication CONNECTION LIMIT 5;"

##### 1.1 pg_hba.conf

host	replication	replication	192.168.50.101/32	trust
host	replication	replication	192.168.50.100/32	trust

##### 1.2 postgres.conf

listener_address = 192.168.50.100
wal_level = hot_standby
synchronous_commit = local
archive_mode = on
archive_command= ''
max_wal_senders = 2
wal_keep_segments = 10
synchronous_standby_names = 'standby'

create archive dir

restart

#### 2. standby

rm /var/lib/pgsql/11/data

pg_basebackup -h 192.168.50.100 -U replication -D /var/lib/pgsql/11/data -P --wal-method=stream

postgres.conf

listener_address = 192.168.50.101
hot_standby = on

recovery.conf

<pre>
standby_mode = on
primary_conninfo = 'host=192.168.50.100 port=5432 user=replication password=swimming3 application_name=standby'
trigger_file = '/tmp/postgresql.trigger.5432'
</pre>

#### 3. check

primary

![](pic/pic01.png)

psql -c "select application_name, state, sync_priority, sync_state from pg_stat_replication;"
psql -x -c "select * from pg_stat_replication;"

![](pic/pic02.png)

create table testtable( id serial primary_key, name varchar(50);
insert into testtable values (2,'vasya'),(3,'petya');

standby

![](pic/pic03.png)
select * from testtable;

#### 4. Backup - pg_backrest

mkdir /opt/backup

### 5. Ссылки

- https://blog.vpscheap.net/how-to-setup-replication-for-postgresql-in-centos-7/
- https://linuxhint.com/setup_postgresql_replication/
- https://opensource.com/article/17/6/ansible-postgresql-operations
- https://www.postgresql.org/docs/11/gssapi-auth.html

- https://info.crunchydata.com/blog/pgbackrest-performing-backups-on-a-standby-cluster
- https://shiningapples.net/%D0%BD%D0%B0%D1%81%D1%82%D1%80%D0%BE%D0%B9%D0%BA%D0%B0-%D0%B1%D0%B5%D0%BA%D0%B0%D0%BF%D0%B0-postgresql-%D0%B2-ubuntu-server-%D0%BF%D1%80%D0%B8-%D0%BF%D0%BE%D0%BC%D0%BE%D1%89%D0%B8-pgbackrest-%D1%81/

- https://pgconf.ru/media/2017/04/04/EgorRogov_pg_probackup_script.txt

!!!
- https://pgstef.github.io/2018/11/28/combining_pgbackrest_and_streaming_replication.html