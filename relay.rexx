/* RELAY EXEC CHAT PROGRAM             */
/*                                     */
/* An NJE (bitnet/HNET) chat server    */
/* for z/VM, VM/ESA and VM/SP          */
/* by collaboration of Peter Jacob,    */
/* Neale Ferguson, Moshix              */
/*                                     */
/* copyright 2020, 2021  by moshix     */
/* Apache 2.0 license                  */
/***************************************/
/* execute this from RELAY VM before starting RELAY CHAT:            */
/* defaults set tell msgcmd msgnoh to remove host(user) in output    */
/*  CHANGE HISTORY                                                   */
/*  V0.1-0.9:  testing WAKEUP mechanism                              */
/*  v1.0    :  double linked list for in memory processing,bug fixing*/
/*  v2.0    :  Configurble parameters, remove hardwired data         */
/*  v2.1    :  Add LPAR and machine measurement for stats            */
/*  v2.2    :  Add /SYSTEM command                                   */
/*  v2.3    :  Make VM/SPrel6 compatible via compatibility=1 parm    */
/*  v2.4    :  Add /FORCE option to force off users (sysop only)     */
/*  v2.5    :  Loop detetector incoming msg counter v1.0             */
/*  v2.6    :  Loop detector v2.0                                    */
/*  v2.7    :  loop detector v3.0                                    */
/*  v2.7.1  :  autodetect who am i                                   */
/*  v2.7.2  :  fix stats, high msg rate and last time user seen      */
/*  v2.7.3  :  loop detector disabled for now until i figure it out  */
/*  v2.7.4  :  differentiate compatibility for VMSP,VMESA and z/VM   */
/*  v2.7.6  :  minor coemstic stuff                                  */
/*  v2.8.0  :  more fixes                                            */
/*  v2.8.1  :  Loop detector and sanity checks                       */
/*  v2.8.2  :  LOGOFF user count fix                                 */
/*  v2.8.3  :  message sender doesn't see her own message anymore    */
/*  v2.8.4  :  Some tests before starting RELAY CHAT                 */
/*  v2.8.5  :  Fix expired users still lingering in linked list      */
/*  v2.9.0  :  Rooms!! Up to 10 char long room name by PeterJ        */
/*  v2.9.1  :  fancy shmancy HELP graphic                            */
/*  v2.9.2  :  Fix potential RSCS authorization error HCPMFS057I     */
/*  v2.9.3  :  Fix ROOMS bug leading to DMTPAF208E error and loop    */
/*  v2.9.4  :  More ROOMS bug fixing and remove /FORCE               */
/*  v2.9.5  :  Error handling for most common NJE errors             */
/*  v2.9.6  :  More loop detector fixes..... thanks PeterJ!          */
/*  v2.9.7  :  Fix expired users still in rooms bug                  */
/*  v2.9.9  :  Spit out operational warnings due to config parms     */
/*  v3.0.0rc1  Release candidate 1 for major rel 3.0                 */
 
 
/* configuraiton parameters - IMPORTANT                               */
relaychatversion="3.0.0rc1" /* must be configured!                    */
timezone="CDT"           /* adjust for your server IMPORTANT          */
maxdormant =5800         /* max time user can be dormat               */
localnode=""             /* localnode is now autodetected as 2.7.1    */
shutdownpswd="1zzzzzz29" /* any user with this passwd shuts down rver*/
osversion="z/VM 6.4"     /* OS version for enquries and stats         */
typehost="IBM z114"     /* what kind of machine                      */
hostloc  ="Stockholm,SE" /* where is this machine                     */
sysopname="zzzzzzzz"     /* who is the sysop for this chat server     */
sysopemail="zzzzzzzgmail" /* where to contact this systop             */
compatibility=3           /* 1 VM/SP 6, 2=VM/ESA 3=z/VM and up        */
sysopuser='MAINT'         /* sysop user who can force users out       */
sysopnode=translate(localnode) /* sysop node automatically set        */
raterwatermark=28000      /* max msgs per minute set for this server  */
debugmode=0               /* print debug info on RELAY console when 1 */
send2ALL=0                /* 0 send chat msgs to users in same room   */
                          /* 1 send chat msgs to all logged-in users  */
log2file=1                /* all calls to log also in RELAY LOG A     */
                          /* make sure to not run out of space !!!    */
 
 
/* global variables                                                  */
                          /* RSCS error messages we need to catch    */
returnNJEmsg= "HCPMSG045E"/* messages returning for users not logged on */
returnNJEmsg2="DMTRGX334I"/* looping error message flushed         */
returnNJEmsg3="HCPMFS057I"/* RSCS not receiving message            */
returnNJEmsg4="DMTPAF208E"/* Invalid user ID message               */
returnNJEmsg5="DMTPAF210E"/* RSCS DMTPAF210E Invalid location      */
 
loggedonusers = 0        /* online user at any given moment        */
highestusers = 0         /* most users online at any given moment  */
totmessages  = 0         /* total number of msgs sent              */
otime = 0                /* overtime to log off users after n minutes */
starttime=mytime()       /*  for /SYSTEM                           */
starttimeSEC=ExTime()    /*  for msg rate  calculation             */
logline = " "            /* initialize log line                    */
receivedmsgs=0           /* number of messages received for stats and loop*/
premsg.0=6               /* needed for loop detector to compare    */
premsg.1=""
premsg.2=""
premsg.3=""
premsg.4=""
premsg.5=""
premsg.6=""
msgrotator=1             /* this will rotate the 7 prev msgs       */
err1="currently NOT"
err2="to logon on"
err3="Weclome to RELAY chat"
err4="logged off now"
loopCondition = 0        /* when a loop condition is detected this will turn to 1 */
 
 
 
/*---------------CODE SECTION STARTS BELOW --------------------------*/
whoamiuser=""             /* for autoconfigure                        */
whoaminode=""
whomistack=""
call whoami               /* who the fahma am I??                     */
say 'Hello, I am: '||whoamiuser||' at '||whoaminode||' with '||whoamistack
 
localnode=whoaminode   /* set localnode */
 
if compatibility > 2 then do /* must be z/VM       , ie min requirement VM level*/
 
     parse value translate(diag(8,"INDICATE LOAD"), " ", "15"x) ,
       with 1 "AVGPROC-" cpu "%" 1 "PAGING-"  page "/"
 say 'All CPU avg: 'cpu '%     Paging: 'paging()
 
     say 'Machine type: 'configuration()'     RAM: 'rstorage()
     say 'Number of CPUs in LPAR: 'numcpus()
 END
     say '                        '
     say '****** LOG BELOW *******'
 
/* some simple logging  for stats etc        */
      CALL log('RELAY chat '||relaychatversion||' initializing...')
 
 
/* init double linked list of online users   */
call @init
 CALL log('List has been initialized.')
 CALL log('List size: '||@size())
if @size() /= 0 then do
   CALL log('Linked list init has failed! Abort ')
   signal xit;
end
 
/*
if emptybuff() < 0 then do
   CALL log('General error in draining buffer.  Abort!')
   signal xit;
end   */
 
/* warn upon certain config parm constellations     */
 
if log2file=1 then call log ("Logging to console AND RELAY LOG A. Keep enough disk space")
if send2ALL=0 then call log ("RELAY CHAT will send chats users in same room, send2ALL = 0")
if send2ALL=1 then call log ("RELAY CHAT will not send chats to users, send2ALL=1")
if compatibility =1 then call log ("RELAY CHAT starting in VM/SP mode")
if compatibility =2 then call log ("RELAY CHAT starting in VM/ESA mode")
if compatibility =3 then call log ("RELAY CHAT starting in z/VM mode")
if compatibility =-1 then call log ("RELAY CHAT starting in MVS/3.8NJE mode")
if debugmode = 0 then call log ("Debug mode is turned OFF")
if debugmode = 1 then call log ("Debug mode is turned ON")
 
 
/*-------------------------------------------*/
signal on syntax
/* now run a quick self test to see if NJE is working (RSCS up?) before continuing
if selftest() < 0 then do
 CALL log('NJE Self Test failed. RSCS not running or previous messages in buffer...')
end
else do
 CALL log('NJE Self Test passed...')
end */
 
 CALL log('********** RELAY CHAT START **********')
 say '    ____  ____  __      __   _  _     ___  _   _    __   ____      '
 say '   (  _ \( ___)(  )    /__\ ( \/ )   / __)( )_( )  /__\ (_  _)     '
 say '    )   / )__)  )(__  /(__)\ \  /   ( (__  ) _ (  /(__)\  )(       '
 say '   (_)\_)(____)(____)(__)(__)(__)    \___)(_) (_)(__)(__)(__)      '
 say '                                                                   '
 say '  Welcome to RELAY CHAT for z/VM,VM/ESA,VM/SP,MVS/3.8 NJE  -  V'relaychatversion
 say ''
 
 
 
/* Invoke WAKEUP first so it will be ready to receive msgs */
/* This call also issues a 'SET MSG IUCV' command.         */
 
  'SET MSG IUCV'
  "WAKEUP +0 (IUCVMSG"
 
  'MAKEBUF'
/* In this loop, we wait for a message to arrive and       */
/* process it when it does.  If the "operator" types on    */
/* the console (rc=6) then leave the exec.                 */
 
/* ******************************************************* */
/* the forever loop below runs all the time and is the     */
/* processing loop for all incoming messages.              */
/* Since WAKEUP is a blocking call, this loop cannot really*/
/* every be overrun by too much load. All accumulated msgs */
/* just grow the buffer while this loop processes each     */
/* incoming mesasge. This makes it exceptionally reliable. */
/* ******************************************************* */
 
  Do forever;
     'wakeup (iucvmsg QUIET'   /* wait for a message         */
     parse pull text           /* get what was send          */
    CurrentTime=Extime()
     select
        when Rc = 5 then do;   /* we have a message          */
           if pos('From', text) > 0 then  do
              parse var text type sender . nodeuser msg
              parse var nodeuser node '(' userid '):'
              CALL LOG('from '||userid||' @ '||node||' '||msg)
              receivedmsgs= receivedmsgs + 1
              /* below line checks if high rate watermark is exceeded */
              /* and if so.... exits!                                 */
              call highrate (receivedmsgs)
              uppuserid=TRANSLATE(userid)
              if detector(msg) > 0 then call handlemsg  userid,node,msg
 
          end
          else do;  /* simple msg from local user  */
        /* format is like this:                           */
        /* *MSG    MAINT    hello                         */
              parse var text type userid msg
                   node = localnode
               call handlemsg  userid,node,msg
           end
        end
        when Rc = 6 then
          signal xit
        otherwise
     end
 end;   /* of do forever loop  */
 
syntax:
call LOG("Error signal was triggered, rc: "||rc)
signal xit;
 
xit:
/* when its time to quit, come here    */
 
  'WAKEUP RESET';        /* turn messages from IUCV to ON    */
  'SET MSG ON'
  'DROPBUF'
exit;
 
errorhandler:
parse ARG msg            /* what error are we checking for/  */
if (msg = returnNJEmsg)  | (msg = returnNJEmsg2) | (msg = returnNJEmsg3) | ,
   (msg = returnNJEmsg4) | (msg= returnNJEmsg5) then return 1
else return 0
 
handlemsg:
/* handle all incoming messages and send to proper method */
   parse ARG userid,node,msg
    userid=strip(userid)
    node=strip(node)
    CurrentTime=Extime()
    umsg = translate(msg)  /* make upper case */
    umsg=strip(umsg)
if debugmode=1 then say "handlemsg func: USERID,NODE,MSG: "userid" @ "node": "msg
    /* below few lines: error handling                 */
    loopmsg=SUBSTR(umsg,1,10) /* extract RSCS error msg */
if errorhandler(loopmsg) > 1 then do
         loopCondition = 1
         /* silently  drop message and don't process it */
         call log('Loop detector triggered for user:  '||userid||'@'||node)
         return
 end
 commandumsg=SUBSTR(umsg,2,5)
 
   updbuff=1
   SELECT                             /* HANDLE MESSAGE TYPES  */
      when (umsg = "/WHO") then
           call sendwho userid,node
      when (umsg = "/SYSTEM") then
           call systeminfo userid,node
      when (umsg = "/STATS") then
           call sendstats userid,node
      when (umsg = "/LOGOFF") then do
           call logoffuser userid,node
           updbuff=0                 /* removed, nothing to update */
      end
      when (umsg = "/LOGON") then do
           call logonuser  userid,node
           call enterRoom userid,node,'GENERAL'   /* enter default GENERAL room */
           updbuff=0                    /* already up-to-date */
      end
      when (pos("/ROOMS",umsg)>0) then do
           call ShowRooms userid,node
      end
      when (pos("/ROOM",umsg)>0) then do
           call EnterRoom  userid,node,umsg
      end
      when umsg='/ECHO' then do
               'TELL' userid 'AT' node 'USER: 'userid' Node: 'node
      end
      when (umsg = "/HELP") then do
           call helpuser  userid,node
      end
      when (umsg = shutdownpswd) then do
           call  log( "Shutdown initiated by: "||userid||" at node "||node)
           signal xit
      end
 
 
      otherwise
           call sendchatmsg userid,node,msg
        end
   if updBuff=1 then call refreshTime currentTime,userid,node /* for each msg ! */
   call CheckTimeout currentTime
return
 
 
sendchatmsg:
/* what we got is a message to be distributed to all online users */
    parse ARG userid,node,msg
if  userid = "RELAY" | userid = "RSCS" then do
    /* don't send to service VMs */
    if debugmode=1 then say "sendchatmsg func: USERID,NODE,MSG: "userid"@"node"; "msg
     CALL LOG('Attention!!! Got message from illegal user: '||userid||' @ '||node)
    return
end
   CurrentTime=Extime()
   call CheckTimeout currentTime
 
    listuser = userid || "@"||node
    if pos('/'listuser,$.@)>0 then do
      /*  USER IS ALREADY LOGGED ON */
             do ci=1 to words($.@)
                entry=word($.@,ci)
                if entry='' then iterate
                parse value entry with '/'cuser'@'cnode'('otime')'
                     if cuser = userid & cnode = node then do
               /* dont' send msg to orignl sender */
                 if userid \= "RSCS" & loopCondition =0 then 'TELL' cuser 'AT' cnode '-->'
                      end
                      else do
                if send2ALL=1 & userid \= "RSCS" & loopCondition = 0 ,
                      then  'TELL' cuser 'AT' cnode '<> 'userid'@'node':'msg
                      end
             end
            totmessages = totmessages+ 1
            prevmsg.1=msg /* for loop detector */
    end
      else do
        /* USER NOT LOGGED ON YET, LET'S SEND HELP TEXT */
      'TELL' userid 'AT' node 'You are currently NOT logged on.'
      'TELL' userid 'AT' node 'Welcome to RELAY chat for z/VM v'relaychatversion
      'TELL' userid 'AT' node '/HELP for help, or /LOGON to logon on'
         totmessages = totmessages + 3
         return
      end
/* -----------------------------------------------------------------
 * this coding sends the message to all logged-in room mates
 *  send2ALL is 0
 * -----------------------------------------------------------------
 */
   if symbol('$Room.userid')<>'VAR' then do
      'TELL ' userid 'AT' node 'You have not entered a room yet, messages can't be sent'
      return
   end
    myRoom=$Room.userid
    do ci=1 to words($Room.myRoom)
       entry=word($Room.myRoom,ci)
       if entry='' then iterate
       if entry=userid'@'node then iterate /* don't send msgs to yourself */
           'TELL ' userid 'AT' node 'Message sent to: 'entry
       parse value entry with cuser'@'cnode
           'TELL ' cuser 'AT' cnode '<> 'userid'@'node':'msg
       totmessages = totmessages+ 1
     end
 
return
 
sendwho:
/* who is online right now on this system? */
   userswho = 0    /* counter for seen usres */
   parse ARG userid,node
 
   CurrentTime=Extime()
   call CheckTimeout currentTime
 
   listuser = userid || "@"||node
   'TELL' userid 'AT' node '> List of currently logged on users:'
   totmessages = totmessages + 1
   do ci=1 to words($.@)
      entry=word($.@,ci)
      if entry='' then iterate
      parse value entry with '/'cuser'@'cnode'('otime')'
      currenttime=Extime()
      lasttime=currenttime-otime
      'TELL' userid 'AT' node '> ' cuser'@'cnode'  - last seen: 'lasttime' seconds ago'
      totmessages = totmessages + 1
      userswho = userswho + 1
   end
  'TELL' userid 'AT' node '> Total online right now: 'userswho
   loggedonusers = userswho
  totmessages = totmessages + 1
return
 
logoffuser:
   parse ARG userid,node
   listuser = userid || "@"||node
   ppos=pos('/'listuser,$.@)
   if ppos=0 then do
           call log("User logoff rejected, not logged-on:  "||listuser)
      return
   end
   rpos=pos(' ',$.@,ppos+1)
   if rpos=0 then rpos=length($.@)+1
   rlen=rpos-ppos
   $.@=overlay(' ',$.@,ppos,rlen)
   $.@=space($.@)
   loggedonusers = @size()
    call log("User removed   : "||listuser)
   CALL log('List size: '||@size())
  'TELL' userid 'AT' node '-> You are logged off now.'
  'TELL' userid 'AT' node '-> New total number of users: 'loggedonusers
 
   call exitRoom userid,node   /* remove this user also from rooms */
 
   totmessages = totmessages + 2
return
 
 
 logonuser:
 /* add user to linked list */
    parse ARG userid,node
    listuser = userid"@"node
    if pos('/'listuser,$.@)>0 then do
       call log("List already logged-on: "||listuser)
      'TELL' userid 'AT' node '-> You are already logged on.'
      'TELL' userid 'AT' node '-> total number of users: '@size()
    end
    else do
       loggedonusers = @size()
 
       if highestusers < loggedonusers then highestusers = highestusers + 1
 
       call @put '/'listuser'('currentTime')'
       call log("List user added: "||listuser)
       CALL log('List size: '||@size())
      'TELL' userid 'AT' node '-> LOGON succeeded.  '
 
      'TELL' userid 'AT' node '-> Total number of users: '@size()
      'TELL' userid 'AT' node '*************************************************'
      'TELL' userid 'AT' node '-> New /ROOM Cobol (example) command'
      'TELL' userid 'AT' node '-> New /ROOMS command to list all rooms with users'
      'TELL' userid 'AT' node '*************************************************'
      'TELL' userid 'AT' node '                          '
       call announce  userid, node /* announce to all users  of new user */
    end
    totmessages = totmessages+ 7
 return
 
systeminfo:
/* send /SYSTEM info about this host  */
     parse ARG userid,node
     listuser = userid"@"node
 
   CurrentTime=Extime()
   call CheckTimeout currentTime
 
     parse value translate(diag(8,"INDICATE LOAD"), " ", "15"x) ,
       with 1 "AVGPROC-" cpu "%" 1 "PAGING-"  page "/"
     cpu = right( cpu+0, 3)
    'TELL' userid 'AT' node '-> NJE node name        : 'localnode
    'TELL' userid 'AT' node '-> Relay chat version   : 'relaychatversion
    'TELL' userid 'AT' node '-> OS for this host     : 'osversion
    'TELL' userid 'AT' node '-> Type of host         : 'typehost
    'TELL' userid 'AT' node '-> Location of this host: 'hostloc
    'TELL' userid 'AT' node '-> Time Zone of RELAY   : 'timezone
    'TELL' userid 'AT' node '-> SysOp for this server: 'sysopname
    'TELL' userid 'AT' node '-> SysOp email addr     : 'sysopemail
    'TELL' userid 'AT' node '-> System Load          :'cpu'%'
    if compatibility > 2 then do
       page=paging()
       rstor=rstorage()
       cfg=configuration()
       lcpus=numcpus()
   /*  parse var mcpu mpage mcf mrstor mlcpus  */
      'TELL' userid 'AT' node '-> Pages/Sec            : 'page
      'TELL' userid 'AT' node '-> IBM Machine Type     : 'cfg
      'TELL' userid 'AT' node '-> Memory in LPAR or VM : 'rstor
      'TELL' userid 'AT' node '-> Number of CPUs       : 'lcpus
    end
     if compatibility > 2 then do
     totmessages = totmessages + 13
     end
    else do
     totmessages = totmessages + 9
    end
return
 
 
sendstats:
/* send usage statistics to whoever asks, even if not logged on */
    parse ARG userid,node
    onlinenow = countusers(userid,node)
 
     parse value translate(diag(8,"INDICATE LOAD"), " ", "15"x) ,
       with 1 "AVGPROC-" cpu "%" 1 "PAGING-"  page "/"
     cpu = right( cpu+0, 3)
    actualtime=Extime()
    elapsedsec=(actualtime-starttimeSEC)
    if elapsedsec = 0 then elapsedsec = 1 /* avoid division by zero on Jan 1 at 00:00 */
 
    msgsrate = (receivedmsgs + totmessages) / elapsedsec
    msgsratef= FORMAT(msgsrate,4,2) /* rounding */
    msgsratef = STRIP(msgsratef)
    listuser = userid"@"node
    'TELL' userid 'AT' node '-> Total number of users: '@size()
    'TELL' userid 'AT' node '-> Highest nr.  of users: 'highestusers
    'TELL' userid 'AT' node '-> Total number of msgs : 'totmessages
    'TELL' userid 'AT' node '-> Messages rate /second: 'msgsratef
    'TELL' userid 'AT' node '-> Server up since      : 'starttime' 'timezone
    'TELL' userid 'AT' node '-> System CPU load      : 'STRIP(cpu)'%'
    'TELL' userid 'AT' node '-> RELAY CHAT version   : v'relaychatversion
 
     totmessages = totmessages+ 7
     call writestats                               /* write stats to disk for now */
return
 
helpuser:
/* send help menu */
  parse ARG userid,node
  listuser = userid"@"node
 
 
'TELL' userid 'AT' node '   ____  ____  __      __   _  _     ___  _   _    __   ____      '
'TELL' userid 'AT' node '  (  _ \( ___)(  )    /__\ ( \/ )   / __)( )_( )  /__\ (_  _)     '
'TELL' userid 'AT' node '   )   / )__)  )(__  /(__)\ \  /   ( (__  ) _ (  /(__)\  )(       '
'TELL' userid 'AT' node '  (_)\_)(____)(____)(__)(__)(__)    \___)(_) (_)(__)(__)(__)      '
'TELL' userid 'AT' node '                                                                  '
'TELL' userid 'AT' node ' Welcome to RELAY CHAT for z/VM,VM/ESA,VM/SP,MVS  V'relaychatversion
'TELL' userid 'AT' node '                                                                  '
'TELL' userid 'AT' node '/HELP   for this chat version'
'TELL' userid 'AT' node '/WHO    for connected users'
'TELL' userid 'AT' node '/LOGON  to logon to this chat room and start getting chat messages'
'TELL' userid 'AT' node '/LOGOFF to logoff and stop getting chat messages'
'TELL' userid 'AT' node '/STATS  for chat statistics'
'TELL' userid 'AT' node '/SYSTEM for info aobut this host'
'TELL' userid 'AT' node '/ROOM   NAME (max 10  char) to change to room NAME'
'TELL' userid 'AT' node '/ROOMS  to see all rooms with users'
'TELL' userid 'AT' node '              '
/* 'TELL' userid 'AT' node '/ROOM 1-9 to join any room, default is room zero (0)'*/
'TELL' userid 'AT' node ' messages with <-> are incoming chat messages from users'
'TELL' userid 'AT' node ' messages with   > are service messages from other chat servers'
'TELL' userid 'AT' node ' messages with --> means your message was sent to all other users'
 
  totmessages = totmessages + 18
return
 
countusers:
 parse ARG userid,node
 listuser = userid"@"node
 onlineusers = 0
 do ci=1 to words($.@)
     entry=word($.@,ci)
     if entry='' then iterate
     parse value entry with '/'cuser'@'cnode'('otime')'
     lasttime=ctime-otime
     onlineusers = onlineusers + 1
 end
return onlineusers
 
enterRoom:
  parse upper arg _user,_node,_room
  if word(_room,1)='/ROOM' then _room=word(_room,2)
  rml=length(_room)
  if rml<3 | rml>10 then  ,
         'TELL '_user' AT '_node 'Room must not be below 3 or exceed 10 characters :'_room
  else do
     if symbol('allrooms')<>'VAR' then allrooms=''
     else if pos('/'_room,allrooms)=0 then allrooms=allrooms' /'_room
     call exitRoom _user,_node
     $Room._user=_room
     if symbol('$Room._room')=='VAR' then $Room._room=$Room._room' '_user'@'_node
        else $Room._room=_user'@'_node
 if LEFT(_user,4) \= "$ROO" then  'TELL '_user' AT '_node' You have entered room: '_room
  end
  totmessages = totmessages + 1
return 0
 
ShowRooms:
/* tell logged on users what rooms there are and who is in them */
  parse upper arg userid,node
  if debugmode=1 then say "Showrooms func: userid @ node: "userid" @ "node
  if symbol('allrooms')<>'VAR' | words(allrooms)=0 then do
         'TELL' userid 'AT' node '> All users are in GENERAL room right now...'
     totmessages = totmessages + 1
     return
   end
   do ri=1 to words(allrooms)
      troom=substr(word(allrooms,ri),2)
      if symbol('$Room.troom')<>'VAR' then iterate
      tusers=$Room.troom
          'TELL 'userid' AT 'node '>ROOM   : 'troom' has 'words(tusers)' user(s)'
          'TELL' userid 'AT' node '>Users  : 'tusers
          totmessages = totmessages+2
  end
return 0
 
exitRoom:
/* exit a user from a room */
  parse arg userid,node
  myRoom=$Room._user
  $Room._user=''   /* clear current room entry */
  troom=''
  if symbol('$Room._room')<>'VAR' then return
  do ci=1 to words($Room.myRoom)
     if word($Room.myRoom,ci)=_user'@'node then do
            'TELL 'userid' AT 'node '>You left room: 'myRoom
        iterate
     end
     troom=troom' 'word($Room.myRoom,ci)
  end
  $Room.myRoom=troom
return
 
 
announce:
/* announce newly logged on user to all users */
  parse ARG userid,node
 
  cj=0 /* save logons to remove, else logon buffer doesn't match  */
  do ci=1 to words($.@)
     entry=word($.@,ci)
     if entry='' then iterate
     parse value entry with '/'cuser'@'cnode'('otime')'
     'TELL' cuser 'AT' cnode '-> New user joined:    'userid' @ 'node
  end
 
return
 
 
CheckTimeout:
/* Check if user has not sent any message, automatic LOGOFF */
   arg ctime
   cj=0 /* save logons to remove, else logon buffer doesn't match  */
   do ci=1 to words($.@)
      entry=word($.@,ci)
      if entry='' then iterate
      parse value entry with '/'cuser'@'cnode'('otime')'
/*    say cuser cnode ctime otime ctime-otime*/
      if ctime-otime > maxdormant then do  /* timeout per configuration */
         cj=cj+1
         say 'removed user: 'cnode
         $remove.cj=cuser','cnode
      end
   end
   do ci=1 to cj
      interpret 'call logoffuser '$remove.ci
      call log($remove.ci||'logged off due to timeout reached '||maxdormant|| ' minutes')
   end
return
 
 
 
refreshTime:
/* Refresh last transaction time */
 /*trace i    */
   arg ctime,userid,node
   listuser=userid'@'node
   ppos=pos('/'listuser,$.@)
   if ppos=0 then return              /* user not logged on */
   ppos=pos('(',$.@,ppos+1)           /* find timestamp */
   if ppos=0 then return              /* not found, let it be */
   rpos=pos(')',$.@,ppos+1)+1         /* find end of timestamp  */
   if rpos=0 then return              /* ) not found, let it be */
   rlen=rpos-ppos
   $.@=overlay('('ctime')',$.@,ppos,rlen)
return
 
 
exTime:
/* Calculate Seconds in this year */
  dd=(date('d')-1)*86400
  parse value time() with hh':'mm':'ss
  tt=hh*3600+mm*60+ss
return right(dd+tt,8,'0')
 
 
mytime: procedure
 timenow = left(time(),5)
 hr = left(timenow,2)
 min = right(timenow,2)
 if hr > 12 then timenow         = (hr - 12)'.'min' pm'
   else if hr = 12 then timenow  = hr'.'min' pm'
                    else timenow = hr'.'min' am'
 if left(timenow,1) = '0' then timenow = substr(timenow,2)
 dow     = left(date('weekday'),3)
 day     = right(date('sorted'),2)
 if left(day,1) = '0' then day = substr(day,2)
 month   = left(date('month'),3)
 year    = left(date('sorted'),4)
return timenow',' dow day month year
 
 
p:      return word(arg(1), 1)    /*pick the first word out of many items*/
sy:      say;
         say left('', 30) "   " arg(1) '   ';
         return
@init:   $.@=;
        @adjust: $.@=space($.@);
        $.#=words($.@);
        return
@hasopt: arg o;
        return pos(o, opt)\==0
@size:  return $.#
 
/*                                        */
@del:   procedure expose $.;
        arg k,m;
        call @parms 'km'
         _=subword($.@, k, k-1)   subword($.@, k+m)
         $.@=_;
         call @adjust;
        return
 
@get:    procedure expose $.;     arg k,m,dir,_
         call @parms 'kmd'
         do j=k  for m  by dir  while  j>0  &  j<=$.#
             _=_ subword($.@, j, 1)
        end   /*j*/
         return strip(_)
 
@parms:  arg opt      /*define a variable based on an option.*/
         if @hasopt('k')  then k=min($.#+1, max(1, p(k 1)))
         if @hasopt('m')  then m=p(m 1)
         if @hasopt('d')  then dir=p(dir 1);
         return
 
@put:    procedure expose $.;
            parse arg x,k;
            k=p(k $.#+1);
            call @parms 'k'
            $.@=subword($.@, 1, max(0, k-1))   x   subword($.@, k);
            call @adjust
         return
 
@show:   procedure expose $.;
            parse arg k,m,dir;
            if dir==-1  &  k==''   then k=$.#
            m=p(m $.#);
            call @parms 'kmd';
            say @get(k,m, dir);
         return
 
list:
/* this is only as examples how to use the double linked list
    for future expanesion of this program                      */
   call sy 'initializing the list.'            ;  call @init
   call sy 'building list: blue'               ;  call @put "blue"
   call sy 'displaying list size.'             ;  say  "list size="@size()
   call sy 'forward list'                      ;  call @show
   call sy 'backward list'                     ;  call @show ,,-1
   call sy 'showing 4th item'                  ;  call @show 4,1
   call sy 'showing 5th & 6th items'           ;  call @show 5,2
   call sy 'adding item before item 4: black'  ;  call @put "black",4
   call sy 'showing list'                      ;  call @show
   call sy 'adding to tail: white'             ;  call @put "white"
   call sy 'showing list'                      ;  call @show
   call sy 'adding to head: red'               ;  call @put  "red",0
   call sy 'showing list'                      ;  call @show
return
 
 
log:
/* general logger function                */
/* log a line to console and RELAY LOG A  */
   parse ARG  logline
   say mytime()' :: 'logline
   if log2file = 1 & compatibility = 3 then do
   address command
/*  'PIPE (name logit)',
     '| spec /'mytime()'/ 1 /::/ n /'logLine'/ n',
     '| >> RELAY LOG A'*/
   logline=mytime()||' :: '||logline
     'EXECIO 1 DISKW RELAY LOG A (STRING '||logline
     'FINIS RELAY LOG A'
   end
return
 
cpubusy:
/* how busy are the CPU(s) on this LPAR */
/* extract CPU buy information for stats etc. */
 cplevel = space(cp_id) sl
 strlen = length(cplevel)
 
 parse value translate(diag(8,"INDICATE LOAD"), " ", "15"x) ,
        with 1 "AVGPROC-" cpu "%" 1 "PAGING-"  page "/"
 cpu = right( cpu+0, 3)
return cpu
 
paging:
/* how many pages per second is this LPAR doing? */
/* extra currenct OS paging activity */
 sl = c2d(right(diag(0), 2))
 cplevel = space(cp_id) sl
 strlen = length(cplevel)
 
 parse value translate(diag(8,"INDICATE LOAD"), " ", "15"x) ,
        with 1 "AVGPROC-" cpu "%" 1 "PAGING-"  page "/"
return page
 
rstorage:
 parse value diag(8,"QUERY STORAGE")   with . . rstor rstor? . "15"x
return rstor
 
configuration:
/* return machine configuration */
/* extract machine type etc. */
 if compatibility > 2 then do
Parse Value Diag(8,'QUERY CPLEVEL') With ProdName .
     Parse Value Diag(8,'QUERY CPLEVEL') With uptime  , . . .  .  .  .  . ipltime
 
 
  Parse Value Diag(8,'QUERY CPLEVEL') With ProdName .
  Parse Value Diag(8,'QUERY CPLEVEL') With uptime  , . . .  .  .  .  . ipltime
  parse value stsi(1,1,1) with 49  type   +4 ,
                               81  seq   +16 ,
                              101  model +16 .
 
  parse value stsi(2,2,2) with 33 lnum   +2 ,  /* Partition number       */
                               39 lcpus  +2 ,  /* # of CPUs in the LPAR  */
                               45 lname  +8    /* partition name         */
 
  parse value stsi(3,2,2) with 39 vcpus  +2 ,  /* # of CPUs in the v.m.  */
                               57 cp_id +16
 
  parse value c2d(lnum) c2d(lcpus) c2d(vcpus) right(seq,5) lname model ,
         with     lnum      lcpus      vcpus        ser    lname model .
 
  blist = "- 2097 z10-EC 2098 z10-BC 2817 z196 2818 z114",
          "  2827 zEC12  2828 zBC12 2964 z13 2965 z13s"
 
  brand = strip(translate( word(blist, wordpos(type, blist)+1), " ", "-"))
 
end
return type
 
numcpus:
/* return number of CPUs in this LPAR */
  parse value stsi(1,1,1) with 49  type   +4 ,
                               81  seq   +16 ,
                              101  model +16 .
 
  parse value stsi(2,2,2) with 33 lnum   +2 ,  /* Partition number       */
                               39 lcpus  +2 ,  /* # of CPUs in the LPAR  */
                               45 lname  +8    /* partition name         */
 
  parse value stsi(3,2,2) with 39 vcpus  +2 ,  /* # of CPUs in the v.m.  */
                               57 cp_id +16
 
  parse value c2d(lnum) c2d(lcpus) c2d(vcpus) right(seq,5) lname model ,
         with     lnum      lcpus      vcpus        ser    lname model .
 
  blist = "- 2097 z10-EC 2098 z10-BC 2817 z196 2818 z114",
          "  2827 zEC12  2828 zBC12 2964 z13 2965 z13s 1090 zPDT 3096 z14"
 
  brand = strip(translate( word(blist, wordpos(type, blist)+1), " ", "-"))
 
 
return lcpus
 
highrate:
/* when too many incoming messages per second exit server to avoid CPU overloading */
/* this function detects high msg rate for loop detection purposes
   or for system load abatement purposes                          */
  RATE = 0
  parse ARG receivedmsg
  currentime=Extime()
  elapsedtime=currentime-starttimeSEC
  if elapsedtime = 0 then elapsedtime = 3 /* some machines too fast */
  rate = receivedmsg/elapsedtime
  if rate > raterwatermark then do
     call log ('Rate high watermark exceeded, rate: '||rate)
     signal xit;
   end
  else do
   return 0
   end
return
 
 
detector:
/* detect if a message is looping by extracting middle of an incoming message-> comparing*/
parse ARG msg /* last message in */
 
Middle=center(prevmsg.1,20)
Middle=strip(middle)        /* in case message <50 we will
                               have leading/trailing blanks, drop them */
Opos=pos(middle,msg)       /* middle part in new message */
If opos>0 then do
     prevmsg.1=msg
     say "message looping deteced"
     CALL log('Attention!!! Loop condition detected by detector function!')
     loopCondition = 1
     return -1
 end
prevmsg.1=msg
return 1
 
whoami:
/* determine node name */
"id (stack"
pull whoamiuser . whoaminode . whoamistack
whoamistack=LEFT(whoamistack,5)
return
 
selftest:
/* Send myself an NJE message before starting up to see if all good */
        'DROPBUF'
       'TELL RELAY at 'localnode' TEST100'
       'wakeup (iucvmsg QUIET'   /* wait for a message         */
        parse pull text          /* get what was send          */
        parse var text type sender . nodeuser msg
        parse var nodeuser node '(' userid '):'
       'DROPBUF'
   if msg = "TEST100" then do
      return 0
   end
return -1
 
emptybuff:
/* empty NJE buffer before starting RELAY CHAT */
 
   'MAKEBUF'
  'wakeup (iucvmsg QUIET'   /* wait for a message         */
   parse pull text          /* get what was send          */
   parse var text type sender . nodeuser msg
   parse var nodeuser node '(' userid '):'
  'DROPBUF'
return 0
 
writestats:
/* WRITE STATS TO DISK */
address command
fileid='RELAY STATS A'
record=" "
record=mytime()||" :: totalmessages: "||totmessages||"  highestusers: "||highestusers
 'EXECIO 1 DISKW RELAY STATS A (STRING '||record
 'FINIS RELAY STATS A'
return
