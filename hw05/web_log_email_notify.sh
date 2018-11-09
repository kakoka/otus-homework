#!/bin/bash
###############################
#                              #
# Web log email notify script #
#                              #
###############################
# config section

IFS=$' '
PIDFILE=wlen.pid
LOGDIR=logs
LOGFILE=wlen.log
recipient="vagrant@localhost"
COUNT=30

# date setup
hourago="85 hours ago"
dlog="`date +"%d/%b/%Y %H:%M:%S"`"
datt="`date +"%d/%b/%Y:%H"`"
dacc="`date --date="$hourago" +"%d/%b/%Y:%H"`"
derr="`date --date="$hourago" +"%Y/%m/%d-%H"`"
errd="`echo $derr | sed 's/-/\ /'`"

# functions
send_email()
{
        (
cat - <<END
Subject: hourly web server report
From: no-reply@localhost
To: $recipient
Content-Type: text/plain

From the last hour there is some stats from web server

Report from $dacc to $datt.

We have some ip addresses:
count ip-address
${IP_LIST[@]}

and we have some urls:
count url
${IP_ADDR[@]}

and we have some http codes:
count code
${HTTP_STATUS[@]}

We have some errors:
${ERRORS[@]}

END
) | /usr/sbin/sendmail $1
}

# here we start

if [ -e $PIDFILE ]
then
    echo "$dlog --> Script is running!" >> $LOGFILE 2>&1
    exit 1
else
        echo "$$" > $PIDFILE
        trap 'rm -f $PIDFILE; exit $?' INT TERM EXIT
        IP_LIST+=(`cat $LOGDIR/access.log | grep "$dacc" | awk '{print $1}' | sort | uniq -c | sort -nr | head -$COUNT`)
        IP_ADDR+=(`cat $LOGDIR/access.log | grep "$dacc" | awk '{print $7}' | sort | uniq -c | sort -nr | head -$COUNT`)
        HTTP_STATUS+=(`cat $LOGDIR/access.log | grep "$dacc" | awk '{print $9}' | sort | uniq -c | sort -nr | head -$COUNT`)
        ERRORS+=(`cat $LOGDIR/error.log | grep "$errd" | head -$COUNT`)
        send_email $recipient
        rm -r $PIDFILE
        trap - INT TERM EXIT
        echo "$dlog --> Success" >> $LOGFILE 2>&1
fi