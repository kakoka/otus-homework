## Написать скрипт для крона

Скрипт должен присылать раз в час на заданную почту: 
1. X IP адресов (с наибольшим кол-вом запросов) с указанием кол-ва запросов c момента последнего запуска скрипта
2. Y запрашиваемых url (с наибольшим кол-вом запросов) с указанием кол-ва запросов c момента последнего запуска скрипта
3. все ошибки c момента последнего запуска
4. список всех кодов возврата с указанием их кол-ва с момента последнего запуска
В письме должно быть прописан обрабатываемый временной диапазон, должна быть реализована защита от мультизапуска.

#### 0. Парметры конфигурации скрипта

```bash
IFS=$' '                      # разделитель записей в лог файле
PIDFILE=/var/run/wlen.pid     # укажем pid файл
LOGDIR=logs                   # укажем директорию с логами
LOGFILE=/var/log/wlen.log     # укажем лог файл скрипта
recipient="vagrant@localhost" # укажем адрес, куда посылать письма
XCOUNT=30                     # укажем количество записей, которые будут включены в письмо
YCOUNT=30

# date setup                  # установим дату, начиная от текущей, за которую нам нужны сведения 
                              # можно поставить "1 hour ago" - по условиям задания      
hourago="85 hours ago"
dlog="`date +"%d/%b/%Y %H:%M:%S"`"
datt="`date +"%d/%b/%Y:%H"`"
dacc="`date --date="$hourago" +"%d/%b/%Y:%H"`"
derr="`date --date="$hourago" +"%Y/%m/%d-%H"`"
errd="`echo $derr | sed 's/-/\ /'`"
```

#### 1. IP адреса с наибольшим количеством запросов (20)

```bash
awk -F" " '{print $1}' access.log | sort | uniq -c | sort -nr | head -20
```

#### 2. Запрашиваемые url с наибольшим количеством запросов (20)

```bash
awk -F" " '{print $7}' access.log | sort | uniq -c | sort -nr | head -20
```

#### 3. Все ошибки

```bash
cat error.log | grep "$errd"
```

#### 4. Http коды возврата и их количество (20)

```bash
awk -F" " '{print $9}' access.log | sort | uniq -c | sort -nr
```

Добавляем к этим запросам фильтрацию по дате ($dacc) и указание откуда брать файлы логов ($LOGDIR), параметр количества записеей ($COUNT):

```bash
cat $LOGDIR/access.log | grep "$dacc" | awk '{print $1}' | sort | uniq -c | sort -nr | head -$COUNT
```

Перед этим вычисляем дату, нужно что бы было 1 час назад:

```bash
hourago="1 hour ago"
dacc="`date --date="$hourago" +"%d/%b/%Y:%H"`
```
Полный листинг скрипта [тут](https://github.com/kakoka/otus-homework/blob/master/hw05/web_log_email_notify.sh).

Добавим скрипт в cron с условием запуска раз в час:
<pre>
* */1 * * *  root /bin/sh /web_log_email_notify.sh >/var/log/wlen.log 2>&1
</pre>
с перенаправлением лога самого скрипта в файл.

```bash
mail -u vagrant
```
<details>
  <summary> > U 42 no-reply@localhost.l  Fri Nov  9 12:10  34/789   "hourly web server report"</summary>
<pre>
Message 42:
From root@otuslinux.localdomain  Fri Nov  9 12:14:35 2018
Return-Path: <root@otuslinux.localdomain>
X-Original-To: vagrant@localhost
Delivered-To: vagrant@localhost.localdomain
Subject: hourly web server report
From: no-reply@localhost.localdomain
To: vagrant@localhost.localdomain
Content-Type: text/plain
Date: Fri,  9 Nov 2018 12:14:35 +0000 (UTC)
Status: R

From the last hour there is some stats from web server

Report from 05/Nov/2018:06 to 09/Nov/2018:12.

We have some ip addresses:
count ip-address
1542 88.198.204.16
 409 5.101.113.64
 145 173.234.153.122
 ...

and we have some urls:
count url
 339 /css/fonts/ptserif.css
 339 /css/fonts/ptsanscaption.css
 221 /json/get_section_page
 ...
 
and we have some http codes:
count code
3034 200
1671 302
 198 301
  74 304
   3 415
We have some errors:
...
</pre>
</details>
<br />
#### P.S.

Можно сделать так, что бы параметры запуска скрипта задавались из командой строки. Например:

```bash
web_log_email_notify.sh -l LOGDIR -c COUNT -e recipient
```

Следовательно, необходимо добавить в скрипт проверку в виде примерно такой конструкции:

```bash
while [ -n "$1" ]
do
case "$1" in
  -l) LOGDIR="$2"
    echo "-l value $LOGDIR"
    shift;;
  -c) COUNT="$2"
    echo "-c value $COUNT"
    shift;;
  -e) recipient="$2"
    echo "-e value $recipient";;
  --) shift
    break ;;
  *) echo "$1 is not a true value or option";;
esac
shift
done
```
В общем, можно улучшать бесконечно :)
