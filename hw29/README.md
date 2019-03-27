## PostgreSQL cluster: etcd, HAproxy, patroni.

Задача:

- развернуть кластер PostgreSQL из трех нод. Создать тестовую базу -
проверить статус репликации;
- cделать switchover/failover;
- поменять конфигурацию PostgreSQL, также сделать это с параметром требущими
перезагрузки;
- настроить клиентские подключения через HAProxy.

Описание стенда:

Стенд состоит из 4 виртуальных машин: ns, pg01, pg02, pg03

### 0. Подготовка

Развертывание сервисов NTP, DNS, etcd, HAproxy.

Написаны роли:

- NTP и DNS (из [ДЗ26](https://github.com/kakoka/otus-homework/tree/master/hw26));
- etcd;
- HAproxy.

В старые роли внесены поправки:

- записи A в файлах зон DNS сервера (pg01, pg02, pg03, ns);
- pg01-pg03 синхронизируется с ns по времени - изменение в конфиге chronyd.

Написаны [**ansible роли**](https://github.com/kakoka/otus-homework/tree/master/hw28/provision/roles) для всех компонентов стенда.

### 1. Patroni

### 2. Switchover/Failover

### 3. Изменения конфигурацию PostgreSQL

### 4. подключения через HAProxy

**pg01**

Вывод запросов к серверу о статусе репликации:

Подключимся к базе данных:

```bash
$ sudo -iu postgres
$ psql
```

Создаем базу данных и подключимся к ней:

```sql
postgres=# create database test;
postgres=# \c test
```

Создадим таблицу testtable и добавим в нее данные:

```sql
test=# create table testtable( id serial primary_key, name varchar(50);
test=# insert into testtable values (1,'pasha');
test=# insert into testtable values (2,'vasya'),(3,'petya');
```

**pg02**

Подключимся к базе данных и сделаем запрос на выборку:

```bash
$ sudo -iu postgres
$ psql
postgres=# \c test
postgres=# select * from testtable;
```

### 5. Использование стенда

После клонирования репозитория:

<pre>
$ vagrant up
$ vagrant ssh pg01
</pre>

Через провижн при старте ВМ создание кластера.

Командной `sudo patronictl -c /etc/patroni.yml list` можно посмотреть статус кластера, кто лидер.

<pre>
+---------+--------+----------------+--------+---------+----+-----------+
| Cluster | Member |      Host      |  Role  |  State  | TL | Lag in MB |
+---------+--------+----------------+--------+---------+----+-----------+
|   otus  |  pg01  | 192.168.50.101 | Leader | running |  1 |       0.0 |
|   otus  |  pg02  | 192.168.50.102 |        | running |  1 |       0.0 |
|   otus  |  pg03  | 192.168.50.103 |        | running |  1 |       0.0 |
+---------+--------+----------------+--------+---------+----+-----------+
</pre>

### 6. Ссылки
