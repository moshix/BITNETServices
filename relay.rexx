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
trace 1
/*  CHANGE HISTORY                                                   */
/*  V0.1-1.0:  testing WAKEUP mechanism                              */
/*  v1.0-1.9:  double linked list for in memory processing,bug fixing*/
/*  v2.0    :  Configurble parameters, remove hardwired data         */
/*  v2.1    :  Add LPAR and machine measurement for stats            */
/*  v2.2    :  Add /SYSTEM command                                   */
/*  v2.3    :  Make VM/SPrel6 compatible via compatibility=1 parm    */
/*  v2.4    :  Add /FORCE option to force off users (sysop only)     */
/*  v2.5    :  Loop detetector incoming msg counter v1.0             */
/*  v2.6    :  Add federation v1.0, loop detector v2.0               */
/*  v2.7    :  loop detector v2.0                                    */
/*  v2.7.1  :  autodetect who am i                                   */
/*  v2.7.2  :  fix stats, high msg rate and last time user seen      */
 
 
/* configuraiton parameters - IMPORTANT                               */
relaychatversion="2.7.2" /* needed for federation compatibility check */
timezone="CDT"           /* adjust for your server IMPORTANT          */
maxdormant =  3000       /* max time user can be dormat               */
localnode=""             /* localnode is now autodetected as 2.7.1    */
shutdownpswd="122222229" /* any user with this passwd shuts down rver*/
osversion="z/VM 6.4"     /* OS version for enquries and stats         */
typehost="IBM zPDT"      /* what kind of machine                      */
hostloc  ="Chicago,IL"   /* where is this machine                     */
sysopname="Moshix  "     /* who is the sysop for this chat server     */
sysopemail="mmmmmx@gmail" /* where to contact this systop             */
compatibility=2           /* 1 VM/SP 6, 2=VM/ESA and up               */
sysopuser='MAINT'         /* sysop user who can force users out       */
sysopnode=translate(localnode) /* sysop node automatically set        */
raterwatermark=1000       /* max msgs per minute set for this server  */
 
 
/* Federation settings below                                          */
federation = 0           /*0=federation off,receives/no sending, 1=on */
federated.0 ="HOUVMESA"  /* RELAY on these nodes will get all msgs!   */
federated.1 ="HOUVMSP6"
federatednum = 2         /* how many entries in the list?             */
 
 
 
/* global variables                                                  */
 
 
returnNJEmsg="HCPMSG045E" /* messages returning for users not logged on */
returnNJEmsg2="DMTRGX334I"/* looping error message flushed         */
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
 
 
/*---------------CODE SECTION STARTS BELOW --------------------------*/
whoamiuser=""             /* for autoconfigure                        */
whoaminode=""
whomistack=""
call whoami               /* who the fahma am I??                     */
say 'Hello, I am: '||whoamiuser||' at '||whoaminode||' with '||whoamistack
 
localnode=whoaminode   /* set localnode */
 
if compatibility > 1 then do /* this is not VM/SP 6, ie min requirement VM level*/
 
 say 'All CPU avg: 'cpu '%     Paging: 'paging()
 
     say 'Machine type: 'configuration()'     RAM: 'rstorage()
     say 'Number of CPU: in LPAR: 'numcpus()
 END
     say '                        '
     say '****** LOG BELOW ** ****'
/* some simple logging  for stats etc        */
      CALL log('RELAY chat '||relaychatversion||' started. ')
 
 
/* init double linked list of online users   */
call @init
 CALL log('List has been initialized..')
 CALL log('List size: '||@size())
/*-------------------------------------------*/
 
 
 
/* Invoke WAKEUP first so it will be ready to receive msgs */
/* This call also issues a 'SET MSG IUCV' command.         */
 
  'SET MSG IUCV'
  "WAKEUP +0 (IUCVMSG"
 
  'MAKEBUF'
/* In this loop, we wait for a message to arrive and       */
/* process it when it does.  If the "operator" types on    */
/* the console (rc=6) then leave the exec.                 */
 
/* logon to all federal relay chat servers in the list     */
 
 
  IF FEDERATION = 1 THEN DO  /* IS FEDERATION TURNED ON??  */
     do I =0 to federatednum by 1
       'TELL RELAY at 'federated.i '/LOGON'
     end
  END
  Do forever;
     'wakeup (iucvmsg QUIET'   /* wait for a message         */
     parse pull text          /* get what was send          */
     select
        when Rc = 5 then do;  /* we have a message          */
        /* parse it                                       */
           if pos('From', text) > 0 then  do  /* from RSCS   */
        /* format is like this:                           */
        /* *MSG    RSCS     From ZVM71X1(OPERATOR): hello */
              parse var text type sender . nodeuser msg
          /* break out the node and userid               */
              parse var nodeuser node '(' userid '):'
          CALL LOG('from'||userid||' @ '||node||msg)
          receivedmsgs= receivedmsgs + 1
          /* below line checks if high rate watermark is exceeded */
          /* and if so.... exits!                                 */
          call highrate (receivedmsgs)
          call detector (msg)
          call handlemsg  userid,node,msg
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
 end;
 
 
 
 
xit:
/* when its time to quit, come here    */
 
  'WAKEUP RESET';        /* turn messages from IUCV to ON    */
  'SET MSG ON'
  'DROPBUF'
  exit;
 
 
handlemsg:
/* handle all incoming messages and send to proper method */
   parse ARG userid,node,msg
    userid=strip(userid)
    node=strip(node)
    CurrentTime=Extime()
   umsg = translate(msg)  /* make upper case */
   umsg=strip(umsg)
 
    /* below few lines: loop detector                  */
    loopmsg=SUBSTR(umsg,1,11) /* extract RSCS error msg */
    if (loopmsg  = returnNJEmsg | loopmsg = returnNJEmsg2)  then do
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
           updbuff=0                    /* already up-to-date */
      end
      when (umsg = "/HELP") then do
           call helpuser  userid,node
      end
      when (umsg = shutdownpswd) then do
           call  log( "Shutdown initiated by: "||userid||" at node "||node)
           signal xit
      end
      when (commandumsg = 'FORCE') then do
           call force userid,node,msg
      end
 
 
      otherwise
           call sendchatmsg userid,node,msg
        end
   if updBuff=1 then call refreshTime currentTime,userid,node /* for each msg ! */
   call CheckTimeout currentTime
return
 
force:
/* sysop forces a user out  */
  parse ARG userid,node,msg
  forceuser = SUBSTR(msg,11,7)  /* extract user after /force command */
  forceuser = strip(forceuser)
/* say "user to be forced, as i understood it: "forceuser    */
  if (userid = sysopuser & node = sysopnode) then do /* ok user is authorized */
     listuser = forceuser || "@"||node
 
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
        CALL LOG('Forced: '||forceuser||' @ '||node)
        loggedonusers = loggedonusers - 1
       'TELL' userid 'AT' node '-> This user has been forced off: 'forceuser
       'TELL' userid 'AT' node '-> New total number of users: 'loggedonusers
        totmessages = totmessages + 2
 
  end   /* of (userid=sysopuser) test */
  else do
    CALL LOG('This user:  '||userid||' @ '||node||' tried to force off user: '||forceuser)
    'TELL' userid 'AT' node '-> Not authorized to force off user: 'forceuser
     totmessages = totmessages + 1
  end
return
 
 
 
sendchatmsg:
/* what we got is a message to be distributed to all online users */
    parse ARG userid,node,msg
    listuser = userid || "@"||node
    if pos('/'listuser,$.@)>0 then do
      /*  USER IS ALREADY LOGGED ON */
            /* federation next 4 lines */
           IF FEDERATION = 1 THEN DO  /* IS FEDERATION TURNED ON??  */
            do i = 0 to federatednum by 1
               'TELL RELAY at 'federated.i '<> 'userid'@'node':'msg
                totmessages = totmessages+ 1
            end
          END /* OF THE IF FEDERATION CONDITION..                   */
             do ci=1 to words($.@)
                entry=word($.@,ci)
                if entry='' then iterate
                parse value entry with '/'cuser'@'cnode'('otime')'
                     'TELL' cuser 'AT' cnode '<> 'userid'@'node':'msg
             end
            totmessages = totmessages+ 1
 
    end
      else do
        /* USER NOT LOGGED ON YET, LET'S SEND HELP TEXT */
        'TELL' userid 'AT' node 'You are currently NOT logged on.'
        'TELL' userid 'AT' node 'Wecome to RELAY chat for z/VM v'relaychatversion
        'TELL' userid 'AT' node '/HELP for help, or /LOGON to logon on'
         totmessages = totmessages + 3
      end
return
 
sendwho:
/* who is online right now on this system? */
   userswho = 0    /* counter for seen usres */
   parse ARG userid,node
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
   loggedonusers = loggedonusers - 1
   CALL log('List size: '||@size())
  'TELL' userid 'AT' node '-> You are logged off now.'
  'TELL' userid 'AT' node '-> New total number of users: 'loggedonusers
   totmessages = totmessages + 2
return
 
 
 logonuser:
 /* add user to linked list */
    parse ARG userid,node
    listuser = userid"@"node
    if pos('/'listuser,$.@)>0 then do
       call log("List already logged-on: "||listuser)
      'TELL' userid 'AT' node '-> You are already logged on.'
      'TELL' userid 'AT' node '-> total number of users: 'loggedonusers
    end
    else do
       if loggedonusers < 0 then loggedonusers = 0
       loggedonusers = loggedonusers + 1
 
       if highestusers < loggedonusers then highestusers = highestusers + 1
 
       call @put '/'listuser'('currentTime')'
       call log("List user added: "||listuser)
       CALL log('List size: '||@size())
      'TELL' userid 'AT' node '-> LOGON succeeded.  '
 
      'TELL' userid 'AT' node '-> Total number of users: 'loggedonusers
       call announce  userid, node /* announce to all users  of new user */
    end
    totmessages = totmessages+ 2
 return
 
systeminfo:
/* send /SYSTEM info about this host  */
     parse ARG userid,node
     listuser = userid"@"node
 
     parse value translate(diag(8,"INDICATE LOAD"), " ", "15"x) ,
       with 1 "AVGPROC-" cpu "%" 1 "PAGING-"  page "/"
     cpu = right( cpu+0, 3)
    'TELL' userid 'AT' node '-> NJE node name        : 'localnode
    'TELL' userid 'AT' node '-> Relay chat version   : 'relaychatversion
    'TELL' userid 'AT' node '-> OS for this host     : 'osversion
    'TELL' userid 'AT' node '-> Type of host         : 'typehost
    'TELL' userid 'AT' node '-> Location of this host: 'hostloc
    'TELL' userid 'AT' node '-> Time Zone of         : 'timezone
    'TELL' userid 'AT' node '-> SysOp for this server: 'sysopname
    'TELL' userid 'AT' node '-> SysOp email addr     : 'sysopemail
    'TELL' userid 'AT' node '-> System Load          :'cpu'%'
    if compatibility > 1 then do
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
     if compatibility > 1 then do
     totmessages = totmessages + 12
     end
    else do
     totmessages = totmessages + 8
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
    'TELL' userid 'AT' node '-> Hihgest nr.  of users: 'highestusers
    'TELL' userid 'AT' node '-> Total number of msgs : 'totmessages
    'TELL' userid 'AT' node '-> Messages rate /minute: 'msgsratef
    'TELL' userid 'AT' node '-> Server up since      : 'starttime' 'timezone
    'TELL' userid 'AT' node '-> System CPU laod      : 'STRIP(cpu)'%'
    'TELL' userid 'AT' node '-> RELAY CHAT version   : v'relaychatversion
 
     totmessages = totmessages+ 7
return
 
helpuser:
/* send help menu */
  parse ARG userid,node
  listuser = userid"@"node
 
 
'TELL' userid 'AT' node 'Welcome to RELAY CHAT for z/VM, VM/ESA, VM/SP v'relaychatversion
'TELL' userid 'AT' node '--------------------------------------------------------'
'TELL' userid 'AT' node '              '
'TELL' userid 'AT' node '/HELP   for this help'
'TELL' userid 'AT' node '/WHO    for connected users'
'TELL' userid 'AT' node '/LOGON  to logon to this chat room and start getting chat messages'
'TELL' userid 'AT' node '/LOGOFF to logoff and stop getting chat messages'
'TELL' userid 'AT' node '/STATS  for chat statistics'
'TELL' userid 'AT' node '/SYSTEM for info aobut this host'
'TELL' userid 'AT' node '/FORCE  to force a user off (SYSOP only)'
'TELL' userid 'AT' node '              '
/* 'TELL' userid 'AT' node '/ROOM 1-9 to join any room, default is room zero (0)'*/
'TELL' userid 'AT' node ' messages with <-> are incoming chat messages...'
'TELL' userid 'AT' node ' messages with   > are service messages from chat servers'
 
  totmessages = totmessages + 13
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
  /*  say cuser cnode ctime otime ctime-otime    */
      if ctime-otime> maxdormant then do  /* timeout per configuration */
         cj=cj+1
         say 'removed user: 'cnode
         $remove.cj=cuser','cnode
      end
   end
   do ci=1 to cj
      interpret 'call logoffuser '$remove.ci
      call log($remove.ci||'logged off due to timeout reached '||maxdormant|| ' minutes')
      loggedonusers = loggedonusers -1
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
   parse ARG  logline
   say mytime()' :: 'logline
return
 
 
cpubusy:
 cplevel = space(cp_id) sl
 strlen = length(cplevel)
 
 parse value translate(diag(8,"INDICATE LOAD"), " ", "15"x) ,
        with 1 "AVGPROC-" cpu "%" 1 "PAGING-"  page "/"
 cpu = right( cpu+0, 3)
return cpu
 
paging:
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
 
 
return type
 
numcpus:
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
/* this function detects high msg rate for loop detection purposes
   or for system load abatement purposes                          */
  RATE = 0
  parse ARG receivedmsg
  currentime=Extime()
  SAY "starttimeSEC: "starttimeSEC
  say "raterwatermark: "raterwatermark
  elapsedtime=currentime-starttimeSEC
  if elapsedtime = 0 then elapsedtime = 3 /* some machines too fast */
  say "elapsedtime: "elapsedtime
  rate = receivedmsg/elapsedtime
  say "rate= "rate
  if rate > raterwatermark then do
     call log ('Rate high watermark exceeded... exiting now')
  /* signal xit;*/
   end
  else do
   return 0
   end
return
 
 
detector:
parse ARG msg /* last message in */
if msg = prevmsg.1 then do
     /* we have a looop!! */
     call log ('LOOP DETECTOR TRIGGERED!!! EXITING  ')
     signal xit;
   end
prevmsg.1=msg
say "loop detector active now"
return
 
whoami:
 
"id (stack"
pull whoamiuser . whoaminode . whoamistack
whoamistack=LEFT(whoamistack,5)
return
