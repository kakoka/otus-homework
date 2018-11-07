IP адреса с наибольшим количеством запросов (20)

```bash
awk -F" " '{print $1}' access.log | sort | uniq -c | sort -nr | head -20
```

Запрашиваемые адреса (20)

```bash
awk -F" " '{print $7}' access.log | sort | uniq -c | sort -nr | head -20
```

Коды возврата и их количество с момента запуска

```bash
awk -F" " '{print $9}' access.log | sort | uniq -c | sort -nr
```

Ошибки

```bash
awk -F" " '{print $9}' error.log | sort | uniq -c | sort -nr
```
