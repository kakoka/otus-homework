#!/bin/bash

###############################
#							  #
# Web log email notify script #
#							  #
###############################

# sed
# find

# config section
IFS=$' '
pidfile=/var/run/wlen.pid
LOGDIR=logs
LISTDIR=list
recipient="kakoka@localhost"
COUNT=7

# functions

send_email()
{
		(		
cat - <<END
Subject: hourly web server report 
From: no-reply@localhost
To: $recipient
Content-Type: text/plain

We have some ip addresses:
count ip-address
${IP_LIST[@]}

We have some urls:
count url
${IP_ADDR[@]}

We have some http codes:
count code
${HTTP_STATUS[@]}

We have some errors:
${IP_ADDR[@]}
END
) | /usr/sbin/sendmail $1
}

# here we start

if [ ! -d $LISTDIR ]
then
	mkdir $LISTDIR
fi

if [ -e $LOCKFILE ]
then
	echo "isRunning!"
	exit 1
else
	echo "$$" > $LOCKFILE
	trap 'rm -f $LOCKFILE; exit $?' INT TERM EXIT
	IP_LIST+=(`awk -v dt=$(date --date="1 hour ago" +"%d/%m/%Y:%H") '$1==dt{print $1}' $LOGDIR/access.log | sort | uniq -c | sort -nr | head -$COUNT`)
	IP_ADDR+=(`awk '{print $7}' $LOGDIR/access.log | sort | uniq -c | sort -nr | head -$COUNT`)
	HTTP_STATUS+=(`awk '{print $9}' $LOGDIR/access.log | sort | uniq -c | sort -nr | head -$COUNT`)
	ERRORS+=(`cat $LOGDIR/error.log | sort | uniq -c | head -$COUNT`)
	send_email $recipient
	rm -r $LOCKFILE
	trap - INT TERM EXIT
	echo "END"
fi
