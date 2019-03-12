#!/bin/sh

SLEEP_TIME=15
MAX_TIME=60

sleep 60

set -e

echo "Attempting to create cluster."

until (
    mysqlsh -- dba configure-instance { --port=3306 --host=node01 --user=root --password=swimming3 } && \
    mysqlsh -- dba configure-instance { --port=3306 --host=node02 --user=root --password=swimming3 } && \
    mysqlsh -- dba configure-instance { --port=3306 --host=node03 --user=root --password=swimming3 } && \
    mysqlsh -f /tmp/cluster-setup.js
)
do
    echo "Cluster creation failed."

    if [ $SECONDS -gt $MAX_TIME ]
    then
        echo "Maximum time of $MAX_TIME exceeded."
        echo "Exiting."
        exit 1
    fi

    echo "Sleeping for $SLEEP_TIME seconds."
    sleep $SLEEP_TIME
done

echo "Cluster created."
echo "Exiting."