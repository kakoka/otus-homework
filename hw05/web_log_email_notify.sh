#!/bin/bash

IFS=$' '
LOCKFILE=lock
LOGDIR=logs
LISTDIR=list
recipient="root@localhost"
COUNT=2

IP_LIST=()
IP_ADDR=()
ERRORS=()
HTTP_STATUS=()

kit_cut (){
 	cat $file | while read p; do echo "$file: $p"; done

}

cut_kit (){
	toArr=$(echo $file | awk '{print toupper($0)}' | sed 's/LIST\///')
	echo ${!toArr}
 	cat $file | while read p; do echo "$file: $p" && ${!toArr}+=$p; done
 	}

email_generate (){
	for file in $LISTDIR/*
	do
		case $file in
			$LISTDIR/ip_list) kit_cut; cut_kit ;;
			$LISTDIR/ip_addr) kit_cut ;;
			$LISTDIR/http_status) kit_cut ;;
			$LISTDIR/errors) kit_cut ;;
		esac
	done
}




email_template="Subject: hourly web server report 
From: no-reply@localhost
To: %s
Content-Type: text/plain
We have $q $w $e
"

# if [ -d !$LOGDIR ]
# 	mkdir $LOGDIR
# fi

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
	awk '{print $1}' $LOGDIR/access.log | sort | uniq -c | sort -nr | head -$COUNT > $LISTDIR/ip_list
	awk '{print $7}' $LOGDIR/access.log | sort | uniq -c | sort -nr | head -$COUNT > $LISTDIR/ip_addr
	awk '{print $9}' $LOGDIR/access.log | sort | uniq -c | sort -nr > $LISTDIR/http_status
	cat $LOGDIR/error.log | sort | uniq -c | head -$COUNT > $LISTDIR/errors
	#if [ email_generate ]
	email_generate
		rm -r $LOCKFILE
		trap - INT TERM EXIT
		echo "END"
	# else
	# 	rm -r $LOCKFILE
	# 	trap - INT TERM EXIT
	# 	echo "mail sender error"
	# 	exit 1
	# fi
fi





# function send_email()
# {
# mail -a /tmp/{ip_list,ip_addr,ip_code} "web log report" root@localhost < $  #,ip_errs} # use mail template
# }