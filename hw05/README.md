IP адреса с наибольшим количеством запросов (20)

```bash
awk -F" " '{print $1}' bre.access_log | sort | uniq -c | sort -nr | head -20
```

Запрашиваемые адреса (20)

```bash
awk -F" " '{print $7}' bre.access_log | sort | uniq -c | sort -nr | head -20
```

Коды возврата и их количество с момента запуска

```bash
awk -F" " '{print $9}' bre.access_log | sort | uniq -c | sort -nr
```

Ошибки

awk -F" " '{print $9}' bre.error_log | sort | uniq -c | sort -nr
