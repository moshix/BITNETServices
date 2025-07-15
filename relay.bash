#!/usr/local/bin/bash52  # or wherever your bash rel > 4.2 resides

# RELAY CHAT SERVER WITH FEDERATION
# COPYRIGHT 2021-2025 BY MOSHIX
# This script is loaded at boot time and stays residdent reading from a named pipe
# This requires bash > 4.2.0
# best start this program like this:
# nohup ./relay.bash 0<&- &> my.log.file &
# this way the program runs in background and detaches from tty
# .. or use tmux/screen
#
# DEPENDENCIES:
# - bash > 4.20 
#
# Ver 0.01 - Start to create skeleton
# Ver 0.02 - Added main persistence functions
# Ver 0.03 - Read from named pipe
# Ver 0.04 - add values to associative array onlinuers: timestamp%room
# Ver 0.05 - parse incoming messages from named pipe /root/chat/chat.pipe
# Ver 0.06 - update existing users time stamp upon new message from them
# Ver 0.07 - Parse message payload and handle /stats
# Ver 0.08 - /SYSTEM and Handle lower case upper case commands
# Ver 0.09 - /LOGON handling
# Ver 0.10 - Sent chat messages to all logged on users
# Ver 0.11 - /WHO handling also for non-logged on users
# Ver 0.12 - fixed /WHO now shows logged on users correctly
# Ver 0.13 - handle color for RELAY console and start up messages
# Ver 0.14 - handle logoff
# Ver 0.15 - expire users after > $EXPIRE
# Ver 0.16 - associative array onlineusers now  just key(user) and value(time last active)
# Ver 0.17 - fixed bugs in handling of send_msg where recipient was not formatted correctly
# Ver 0.18 - fixed expiry of old users, add new user and count of logged on users for /STATS
# Ver 0.19 - fixed count of max users
# Ver 0.20 - Make sure only logged on users can send messages!
# Ver 0.21 - Enable logging to RELAY.LOG and fix order of expiry of old users
# Ver 0.22 - /DM direct message from one user to the next
# Ver 0.23 - Catch NJE errros and beginning of throttling algo
# Ver 0.24 - Fix some corner cases of funny formed non-command messages
# Ver 0.30 - Thottling and fixes
# Ver 0.40 - Message loop detection
# Ver 0.50 - better logging
# Ver 0.51 - splash screens / more color options / cosmetics
# Ver 0.60 - Beginning of federation - announce to other systems
# Ver 0.61 - more cosmetics and USR1 signal catching
# Ver 0.65 - trap exit and cleanup
# Ver 0.66 - fix CPU busy calculation
# Ver 0.70 - History of last n users
# Ver 0.80 - Chat history 
# Ver 0.90 - Fixed various small issues (July 2025)
# TODO !!  - Chat lines history for people newly logged in

# Global Variables
VERSION="0.80"
MYNODENAME="CHAT@RELAY"
SHUTDOWNPSWD="========="  # any user with this passwd shuts down rver
OSVERSION="RHEL 7 "       # OS version for enquries and stats       
TYPEHOST="GCLOUD SERVER"  # what kind of machine                     
HOSTLOC="TIMBUKTU    "    # where is this machine                
SYSOPNAME="MOSHIX  "      # who is the sysop for this chat server 
SYSOPEMAIL="SOSO@SOSO  "  # where to contact this systop           
SYSOPUSER='ROOT'          #  sysop user who can force users out     
RATERWATERMARK=800        #  max msgs per minute set for this server 
DEBUGMODE=0               #  print debug info on RELAY console when 1 
SEND2ALL=1                #  0 send chat msgs to users in same room
                          #  1 send chat msgs to all logged-in users
LOG2FILE=1                #  all calls to log also in RELAY LOG A 
                          #  make sure to not run out of space !!!
FEDERATION=0              #  Do we want federation? =1 yes, =0 no
CHATHISTORY=15            #  history goes back n  last chat lines 
HISTORY=15                #  user logon/logff history n entries  
SILENTLOGOFF=0            #  silently logg off user by 1/min wakeup call 
EXPIRE=30                 # expire users after n minutes
EXPIRESECONDS=$(( 60 * $EXPIRE ))
LASTMESSAGETIME=0         # for throttling purposes
LASTMESSAGE1=""
LASTMESSAGE2=""

PIPE="/root/chat/chat.pipe" # location of pipe

loopflag="false"          # for loop detection purposes 
ERRORMSG1="HCPMSG045E"    # messages returning for users not logged on 
ERRORMSG2="DMTRGX334I"    # looping error message flushed        
ERRORMSG3="HCPMFS057I"    # RSCS not receiving message          
ERRORMSG4="DMTPAF208E"    # Invalid user ID message            
ERRORMSG5="DMTPAF210E"    # RSCS DMTPAF210E Invalid location  

# terminal handling globals
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
blue=`tput setaf 4`
magenta=`tput setaf 5`
cyan=`tput setaf 6`
white=`tput setaf 7`
blink=`tput blink`
rev=`tput rev`
reset=`tput sgr0`
# echo "${red}red text ${green}green text${reset}"

# list of nodes to federate with
declare -A federationnodes

# last N users seen online
declare -A lastusers

# users array here!! 
declare -A onlineusers    # importnat associative array ! structure:
                          # onliners[MAINT@SEVMM1]=TIME_OF_LAST_INTERACTION+"%ROOM"
#STARTTIME=`date +%s`
STARTTIME=`date`

INCOMINGSENDER=""          # sender of currently incoming message
INCOMINGMSG=""             # this incoming message in handling
NUMBERMSGS=0               # number of messages sent and received
NUMBERUSERS=0              # number of users currently online
MAXUSERS=0                 # maximum number of users seen online
receivedmsgnumber=0        # number of received messages for throttling
# all functions here. MAIN loop much further below 
# in VIM search for MAINLOOP to get there

init_system() {
clear
echo " ${cyan}" 
echo "   ____  ____  __      __   _  _     ___  _   _    __   ____     "
echo "  (  _ \( ___)(  )    /__\ ( \/ )   / __)( )_( )  /__\ (_  _)    " 
echo "   )   / )__)  )(__  /(__)\ \  /   ( (__  ) _ (  /(__)\  )(      "  
echo "  (_)\_)(____)(____)(__)(__)(__)    \___)(_) (_)(__)(__)(__)     "  
echo "${reset}"
echo "${yellow}Welcome to RELAY CHAT NJE for funetnje, SNA NJE on Linux  ${reset}"
echo " " 
echo  "${red}RELAY CHAT ${green}v$VERSION ${red}SERVER BASH VERSION STARTING...${reset}" 
result=`check_pipe`
#echo "result: $result"
if [[ $result != "true" ]]; then
 tput blink; tput rev;  echo -e  "\033[33;5mNamed pipe /root/chat/chat.pipe does not exist!! RELAY CHAT shutting down now !!\033[0m" ; tput sgr0 
fi
echo  "${red}This is the chat server console.${reset}"
echo "Start time registered: $STARTTIME"
echo "${magenta} " 
echo "ENVIRONMENT:${reset} "
scpu=`awk '{u=$2+$4; t=$2+$4+$5; if (NR==1){u1=u; t1=t;} else print ($2+$4-u1) * 100 / (t-t1) "%"; }' \
<(grep 'cpu ' /proc/stat) <(sleep 1;grep 'cpu ' /proc/stat)`
echo "CPU load currently at.................${green}$scpu ${reset}"
echo "Users expire after minutes............${green}$EXPIRE ${reset}"
echo "Users expire after seconds............${green}$EXPIRESECONDS ${reset}"
echo "This user and host................... ${green}$MYNODENAME ${reset}"
echo "This password can shutdown remotely.. ${green}$SHUTDOWNPSWD ${reset}"
echo "|____________________________________________________________|"
echo " "
echo " "
echo "RELAY CHAT is now running. Console messages below: ${reset} " 
echo " "
touch recent.tmp
}

cleanup () {
# clean up and notify user before exiting
echo "${rev}${red}         RELAY CHAT exiting gracefully now. Wait...       ${reset} "
# announce to federated nodes that I am exiting
# announce_exit
# handle any last incoming messages before quitting to flush pipe
# this will wait for 1 seconds if there is anything coming in, then shutdown 
exec 7<>$PIPE
read -t 1 <&7; echo "RELAY CHAT emptying the NJE pipe now..."
echo " "
local content=$?
if [[ $content != *"@"* ]]; then
  # whatever is in pipe is not an NJE message
  echo "Nothing else in the NJE pipe."
  echo "RELAY CHAT: good bye"
else
  echo "${yellow} This NJE message will be lost: $content ${reset}"
  echo "going..."
  sleep 0.2s
  echo "going...going..."
  sleep 0.2s
  echo "going...going......."
  echo "RELAY CHAT: good bye"
fi
[ -e  recent.tmp ] && rm recent.tmp
[ -e  sorted.recent.tmp ] && rm sorted.recent.tmp  # clean up old files from last_seen function
exit
}

check_pipe () {
# this function checks if the named pipe exists
# -p checks for named pipe, -f for regular file
local FILE=/root/chat/chat.pipe
if test -p "$FILE"; then
    echo "true"
else
    echo "false"
fi
}


logit () {
# log to file all traffic and error messages
if [ $LOG2FILE == "1" ]; then 
  logdate=`date`
  echo "$logdate:$1=$2" >> RELAY.LOG
fi
}

log_error () {
# log to file all traffic and error messages
  logdate=`date`
  echo "$logdate:$1" >> RELAY.ERROR
}

announce_nodes () {
log_error "DMPTY announce_nodes() "
}


dm_user ()  {
# send direct message from one user to another
# first let's make sure we have a from user in $1
# a to user in $2 and a message in $3
for i in "$@"
do
 if [ $i == "" ]; then
  send_msg "$1" ">> Message formatting error for /DM"
fi
done

# we assume input is correct
send_msg "$2" ">> DM from $1:  $3"
}

load_users() {
# first remove duplicate entries before loading
awk '!seen[$0]++' users.txt > onlineusers.array
readarray -t lines < ./onlineusers.array

for line in "${lines[@]}"; do
   key=${line%%=*}
   value=${line#*=}
   onlineusers[$key]=$value  ## Or simply ary[${line%%=*}]=${line#*=}
   let NUMBERUSERS++
done

# for debugging print what we read in from file
for row in "${onlineusers[@]}";do                                                      
  echo $row
done 
}

is_loop () {
# this function finds out if there is a message loop
# a message loop has 3 messages with the same content of beginning of previous msg
# in the last part of the newer message
newmsg=$INCOMINGMSG
if [[ $newmsg == *"$LASTMESSAGE1"* ]] && [[ $newmsg == *"$LASTMESSAGE2"* ]] && [[ $newmsg == *"$LASTMESSAGE3"* ]]; then
    # ok possible loop 
    echo "${red}CHAT600S MESSAGE LOOP DETECT. IGNORING $newmsg ${reset}"
    log_error "CHAT600S MESSAGE LOOP DETECT. IGNORING $newmsg "
    loopflag="true"
fi
LASTMESSAGE1=$newmsg
LASTMESSAGE2=$LASTMESSAGE1
LASTMESSAGE3=$LASTMESSAGE2
}


remove_old() {
# remove expired users from associative array
# set -xT
for row in "${!onlineusers[@]}";do
  value=${onlineusers[$row]}
  retimenow=`date +%s` # date in seconds
  compvalue=$(( retimenow - value ))
  #echo "for user $row resident time is: $compvalue in seconds"
  if (( $compvalue > $EXPIRESECONDS )) ; then
    echo "user $row has exceeded their welcome.."
    log_error "user $row has exceeded no activity time limit and has been logged out. "
    remove_user "$row"
   send_msg "$row" "You have been logged out due to inactivity"  
  fi
done
# set +xT
}


save_users() {
# save currently online users to file for recovery purposes
remove_old #first remove expired users
printf "%s\n" "${onlineusers[*]}"  > users.txt
}

printarr() { 
# print entire array of onlineusers into a file
declare -n p="$1"
for k in "${!p[@]}"; do
   printf "%s %s\n" "$k" "${p[$k]}" >> recent.tmp
 done  
}  


last_seen () {
# send list of last seen $HISTORY users to $1
for k in "${!onlineusers[@]}"; do
   printf "%s %s\n" "$k" "${onlineusers[$k]}" > recent.tmp
done

#printarr "$onlineusers" # print to recent.tmp
echo "/users debug: "`head -n "$HISTORY" recent.tmp | sort -k2 -n `
head -n "$HISTORY" recent.tmp | sort -k2 -n  > sorted.recent.tmp
readarray -t lines < sorted.recent.tmp
ltnow=`date +%s` # now now in seconds
for line in "${lines[@]}"; do
   key=${line%% *}  # they key, ie maint@sevmm1
   if [[ "$1" == "$key" ]]; then   
      #this user is the same as $1 so makes no sense to show
      send_msg "$1" ">> Yourself.... just now" 
      continue
   fi
   value=${line#* } # they value, last time seen online in sec
   lseen=$(( ltnow - value ))
   lseenmin=$(( lseen / 60 ))
   #echo "lseen - lseemin: $lseen - $lseemin"
   
   send_msg "$1" "User $key seen last $lseemin ago"
done
[ -e  sorted.recent.tmp ] && rm sorted.recent.tmp
[ -e recent.tmp ] &&  rm recent.tmp
}

add_user() {
# add new user and time of login - we deal with rooms later
datenow=`date +%s`
#[ ${array[key]+abc} ] && send_msg "$1" "You are already logged in!" || onlineusers[$1]+=$datenow
if [ -v 'onlineusers[$1]' ]; then
  #it exists already
  send_msg "$1" ">> You are already previously logged on.."
else 
  onlineusers[$1]+=$datenow
  send_msg "$1" ">> You are now logged in"
  send_msg "$1" ">> Currently online: "
  
  for row in "${!onlineusers[@]}";do
    send_msg "$1" ">> User: $row"
  done
  send_msg "$1" ">> /HELP for a help menu."
  let NUMBERUSERS++
  if (( $NUMBERUSERS > $MAXUSERS )); then
     MAXUSERS=$((NUMBERUSERS+1))
  fi
fi 
}

send_chatmsg() {
# send non-command chat message to all logged in users $1 is user and $2 is message
# this function only gets one parameter, ie the message
# make sure the sender is actually logged on!
# also keep last 15 messages in a chat array
if [ -v 'onlineusers[$1]' ]; then
  # yes, user is logged on and can send messages

  for row in "${!onlineusers[@]}";do
     # send_msg "$row" "$2"  # $2 in this case is the payload
     /usr/bin/send -m $row "> $2"
     let NUMBERMSGS++
     logit "$1" "$2"
  done
else 
 send_msg "$1" ">> You need to log in to send messages. /HELP or /LOGON"
fi
}

remove_user() {
# remove user from array because of logout or expiry or error message NJE
unset onlineusers[$1]
send_msg "$1" ">> You have been logged off"
}

parse_incoming() {
# parse incomign messages of form: "maint@sevmm1{hello you"
# and turn user into upper case

INCOMINGMSG=`cut -d "}" -f2- <<< "$1"`
INCOMINGSENDER=`sed 's/}.*//' <<< "$1"`
#INCOMINGSENDER=$(echo $INCOMINGSENDER | tr 'a-z' 'A-Z') # turn user into upper case

#echo "incoming payload: $INCOMINGMSG"  # for debug purposes only. works now
#echo "incoming user: $INCOMINGSENDER"

let NUMBERMSGS++
}

do_throttle () {
# in this function we throttle depending on message/sec rate
#time message now ($1) - time since last message= time elapsed
#lastbfore variable contains message tstamp of message before last
let receivedmsgnumber++ # update number of incoming messages
last=$1
elapsed=$((last - lastbefore))
if (($receivedmsgnumber == 0 )); then
  receivedmsgnumber=1 # avoid division by zero
fi
watermark=$((elapsed / receivedmsgnumber))
if ((watermark > 50 )); then
  echo "CHAT800S 50 / SEC WATERMARK REACHED. PAUSING 0.5S"
  log_error "CHAT800S 50 / SEC WATERMARK REACHED. PAUSING 0.5S"

  sleep 0.5s
fi
if ((watermark > 100 )); then
  echo "CHAT801S 100  / SEC WATERMARK REACHED. PAUSING 1S"
  log_error "CHAT801S 100  / SEC WATERMARK REACHED. PAUSING 1S"
  sleep 1s
fi
lastbefore=`date +%s` # reset laste before message tdate
}

update_user () {
datenow=`date +%s`
printf "%s\n" ${!onlineusers[@]}|grep -q $1  && onlineusers[$1]=$datenow 
}

send_msg () {
# sends message and updates counter to $1 user and $2 message
if [ "$2" != "" ]; then
   /usr/bin/send -m $1 $2
   let NUMBERMSGS++
   logit "$1" "$2"
else
   echo "CHAT500E General send_msg formatting error. Message is empty"
   log_error "CHAT500E General send_msg formatting error. Message is empty"
fi
}

handle_msg () {
# handle a new incomign message with par $INCOMINGSENDER $INCOMINGMSG
logit "$1" "IN[$2]"
uppermsg=$(echo $2 | tr 'a-z' 'A-Z')
if [[ $uppermsg == "/STATS" ]]; then
    send_msg "$1" "RELAY CHAT STATISTICS"
    send_msg "$1" "====================="
    send_msg "$1" "Number of messages handled:.......$NUMBERMSGS"
    send_msg "$1" "Maximum number of users:..........$MAXUSERS"
    send_msg "$1" "Current number of online users:...${#onlineusers[*]}"
    send_msg "$1" "This chat server up since:........$STARTTIME"
fi

if [[ $uppermsg == "/SYSTEM" ]]; then
scpu=`awk '{u=$2+$4; t=$2+$4+$5; if (NR==1){u1=u; t1=t;} else print ($2+$4-u1) * 100 / (t-t1) "%"; }' \
<(grep 'cpu ' /proc/stat) <(sleep 1;grep 'cpu ' /proc/stat)`
   send_msg "$1" "Welcome to RELAY CHAT NJE for funetnje, SNA NJE on Linux         "
   send_msg "$1" "Chat Server version:..............$VERSION"
   send_msg "$1" "This chat server up since:........$STARTTIME"
   send_msg "$1" "Contact SYSOP at:.................$SYSOPEMAIL"
   send_msg "$1" "Type of host:.....................$TYPEHOST"
   send_msg "$1" "Host location at:.................$HOSTLOC"
   send_msg "$1" "Host CPU busy in %:...............$scpu"
fi

if [[ $uppermsg == "/LOGON" ]]; then

    add_user "$1"
fi

if [[ $uppermsg == "/LOGIN" ]]; then

    add_user "$1"
fi

if [[ $uppermsg == "/SIGNON" ]]; then

    add_user "$1"
fi

if [[ $uppermsg == "/LOGOFF" ]]; then
    remove_user "$1"
fi

if [[ $uppermsg == "/DM" ]]; then
   dm_user "$1" "$2" "$3"
fi

if [[ $uppermsg == "/USERS" ]]; then
   last_seen "$1"
fi

if [[ $uppermsg == "/WHO" ]]; then
  for row in "${!onlineusers[@]}";do
    send_msg "$1" "User: $row    .......is ONLINE"
  done
  if [[ ${#onlineusers[@]} < 1 ]]; then
    send_msg "$1" "RELAY CHAT USERS LOGGED IN: 0 users "
    send_msg "$1" "/LOGON to logon "
  fi
fi

if [[ $uppermsg == "/HELP" ]]; then
   send_msg "$1" "RELAY CHAT HELP"           
   send_msg "$1" "==============="
   send_msg "$1" "To logon to chat server and chat with others:......../LOGON"
   send_msg "$1" "To log off from chat server........................../LOGOFF"
   send_msg "$1" "To see details about this chat server:.............../SYSTEM"
   send_msg "$1" "To see statistics about this chat server:............/STATS"
   send_msg "$1" "To see who is online now:............................/WHO"
   send_msg "$1" "To see list of recently seen users.................../USERS"
   send_msg "$1" "To send a direct message to another user............./DM" 
   send_msg "$1" "To see this help menu:.............................../HELP"
fi

# must be a pure chat message... send it now
if [[ ${uppermsg:0:1} != "/" ]] ; then
   send_chatmsg "$1" "$2"
else 
   uppermsg="=/="
 fi
#set -v -x +e
}
trap process_USR1 SIGUSR1

process_USR1() {
    echo 'Got signal USR1'
    exit 0
}
# start of program, lets load users list from file
trap cleanup EXIT
init_system

# MAINLOOP  to make editor search easy
#load_users

# process incoming message

while true
do
if read line < /root/chat/chat.pipe; then

    echo "incoming raw message: $line"
    # do we need to throttle?
    if (( lastbefore == 0 )); then 
       lastbefore=`date +%s`
    fi
    messagetstamp=`date +%s`
    do_throttle "$messagetstamp"
    
    # process incoming message now
    # search if sender is in onlineusers, and if so adjust last seen time
    # if not, then look for message payload and then process it in a select structure

    parse_incoming "$line"
#    is_loop "$INCOMINGMSG"  

       update_user "$INCOMINGSENDER"
       remove_old
 if [[ "$INCOMINGMSG" == *"$ERRORMSG1"* ]] || [[ "$INCOMINGMSG" == *"$ERRORMSG2"* ]]  || [[ "$INCOMINGMSG" == *"$ERRORMSG3"* ]] || [[ "$INCOMINGMSG" == *"$ERRORMSG4"* ]]  || [[ "$INCOMINGMSG" == *"$ERRORMSG5"* ]]; then 
          echo "${blink} ${rev} ATTENTION NJE ERROR MESSAGE DETECTED. IGNORING INCOMING MESSAGE: $INCOMINGMSG ${reset}"
            log_error "ATTENTION NJE ERROR MESSAGE DETECTED. IGNORING INCOMING MESSAGE: $INCOMINGMSG "
       else
           if [[ "$loopflag" != "true" ]]; then
             handle_msg "$INCOMINGSENDER" "$INCOMINGMSG"
             loopflag="false"
           fi
       fi
  fi
sleep 0.5
done

# time to shutdown 
save_users
exit
