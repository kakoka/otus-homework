#!/bin/bash

export GZIP=-9

rm -r /tmp/file_{1,2}.dump >/dev/null 2>&1
rm -r /tmp/file_{1,2}.dump.tar.gz >/dev/null 2>&1

# best effort option
function io1 {
  ionice -c 2 dd if=/dev/urandom of=/tmp/file_1.dump bs=1M count=1024 >/dev/null 2>&1
}

# real time option
function io2 {
  ionice -c 3 dd if=/dev/urandom of=/tmp/file_2.dump bs=1M count=1024 >/dev/null 2>&1 
}

# very low priority
function ni1 {
  nice -n -20 tar czf /tmp/file_1.dump.tag.gz /tmp/file_1.dump >/dev/null 2>&1
}

# very high priority
function ni2 {
  nice -n 19 tar czf /tmp/file_2.dump.tag.gz /tmp/file_2.dump >/dev/null 2>&1
}

for i in {1..2}; do {
  echo "ionice $i started"
  time io$i & pid=$!
  PIDS+=" $pid";
} done

trap "kill $PIDS" SIGINT

echo "io functions started"
wait $PIDS
echo "ok"

for i in {1..2}; do {
  echo "nice $i started"
  time ni$i & pid=$!
  PIDS+=" $pid";
} done

trap "kill $PIDS" SIGINT

echo "nice functions started"
wait $PIDS
echo "ok"