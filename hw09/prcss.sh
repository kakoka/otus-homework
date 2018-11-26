#!/bin/bash

IFS=" "

function list_process {
  for pid in $*
   do
     procpid=/proc/$pid
     if [[ -e $procpid/environ && -e $procpid/stat ]]; then
      # form /proc/$pid/stat 
      # 1. $3 - (3) state; - process state flag - 'DRSTWXZ' 
      # 2. $19 - (19) nice; priority range 19 (low priority) to -20 (high priority); flags '<','N',''
      # 3. if $6==$1 (6) session; session leader flag - 's'
      # 4. $20 (20) num_threads; number more than 1, flag - 'l'
      # 5. Memory locks flag - grep from /proc/smaps
      # 6. $8 (8) tpgid; process in foreground, flag -'+'
      
      # TIME in ps is (utime+stime)/CLK_TCK - (14) utime, (15) stime from /proc/$pid/stat
      Time=`awk -v ticks="$(getconf CLK_TCK)" '{print strftime ("%M:%S", ($14+$15)/ticks)}' $procpid/stat`      
      
      # Memory Locks
      Locked=`grep VmFlags $procpid/smaps | grep lo`
      
      #STAT
      
      Stats=`awk '{ printf $3; \
      if ($19<0) {printf "<" } else if ($19>0) {printf "N"}; \
      if ($6 == $1) {printf "s"}; \
      if ($20>1) {printf "l"}}' $procpid/stat; \
      [[ -n $Locked ]] && printf "L"; \
      awk '{ if ($8!=-1) { printf "+" }}' $procpid/stat`
      
      # Command line options from /proc/$pid/cmdline

      Cmdline=`awk '{ print $1 }' $procpid/cmdline | sed 's/\x0/ /g'`
      [[ -z $Cmdline ]] && Cmdline=`strings -s' ' $procpid/stat | awk '{ printf $2 }' | sed 's/(/[/; s/)/]/'`
      
      # TTY grep form /proc/$pid/fd
      qq=`ls -l $procpid/fd/ | grep -E '\/dev\/tty|pts' | cut -d\/ -f3,4 | uniq`
      Tty=`awk '{ if ($7 == 0) {printf "?"} else { printf "'"$qq"'" }}' $procpid/stat`
    
    fi
    printf  '%7d %-7s %-12s %s %-10s\n' "$pid" "$Tty" "$Stats" "$Time" "$Cmdline"
  done
}
ALLPIDS=`ls /proc | grep -P ^[0-9] | sort -n | xargs`
printf  '%7s %-7s %-12s %s %-10s\n' "PID" "TTY" "STAT" "TIME" "COMMAND"
list_process $ALLPIDS