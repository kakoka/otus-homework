#!/bin/sh
/usr/bin/mkdir -p '/usr/pgsql-11/lib'
/usr/bin/mkdir -p '/usr/pgsql-11/share/extension'
/usr/bin/mkdir -p '/usr/pgsql-11/share/extension'
/usr/bin/install -c -m 755  pg_prometheus.so '/usr/pgsql-11/lib/pg_prometheus.so'
/usr/bin/install -c -m 644 .//pg_prometheus.control '/usr/pgsql-11/share/extension/'
/usr/bin/install -c -m 644 .//sql/pg_prometheus--0.2.1.sql  '/usr/pgsql-11/share/extension/'
/usr/bin/mkdir -p '/usr/pgsql-11/lib/bitcode/pg_prometheus'
/usr/bin/mkdir -p '/usr/pgsql-11/lib/bitcode'/pg_prometheus/src/
/usr/bin/install -c -m 644 bitcode/pg_prometheus/src/prom.bc '/usr/pgsql-11/lib/bitcode'/pg_prometheus/src/
/usr/bin/install -c -m 644 bitcode/pg_prometheus/src/parse.bc '/usr/pgsql-11/lib/bitcode'/pg_prometheus/src/
/usr/bin/install -c -m 644 bitcode/pg_prometheus/src/utils.bc '/usr/pgsql-11/lib/bitcode'/pg_prometheus/src/
/usr/bin/install -c -m 644 bitcode/pg_prometheus.index.bc '/usr/pgsql-11/lib/bitcode'