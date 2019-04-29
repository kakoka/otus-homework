SELECT sample
FROM metrics
WHERE time > NOW() - interval '10 min' AND
name = 'netdata_system_active_processes_processes_average' AND
Labels @> '{"instance": "ns:19999"}';


SELECT
  time_bucket ('1m', time) AS time,
  avg(value) as load_1m
FROM
  metrics
WHERE
  time BETWEEN $__timeFrom() AND $__timeTo()
  AND name = 'netdata_users_cpu_system_percentage_average'
  AND labels @> '{"instance": $instance}'
  GROUP BY 1
  ORDER BY 1 ASC;

SELECT DISTINCT labels->'instance' FROM metrics_labels WHERE metric_name = 'netdata_users_cpu_system_percentage_average';


SELECT value AS value, time AS time
FROM metrics 
WHERE time = now() at time zone 'utc'
AND name = 'netdata_cpu_cpu_percentage_average' 
AND labels @> '{"instance": "node03:19999"}';