/**RELAY EXEC CHAT PROGRAM             */
/*                                     */
/* An NJE (bitnet/HNET) chat server    */
/* for z/VM, VM/ESA and VM/SP          */
/* by collaboration of Peter Jacob,    */
/* Neale Ferguson, Moshix             */
/*                                     */
/* copyright 2020 by moshix            */
/* Apache 2.0 license                  */
/***************************************/
 
/* configuraiton parameters - IMPORTANT */
relaychatversion="2.2.1"   /* needed for federation compatibility check */
timezone="CET"             /* adjust for your server IMPORTANT */
maxdormant = 1000          /* max time user can be dormat */
localnode ="houvmzvm"      /* IMPORTANT configure your RSCS node here!! */
shutdownpswd="1sdfj234a"   /* any user who sends this password shuts down the chat server*/
osversion="z/VM 6.4"       /* OS version for enquries and stats         */
typehost="IBM z114"        /* what kind of machine                      */
hostloc  ="Stockholm, SE"  /* where is this machine                   */
osversion="z/VM 6.4"       /* OS version for enquries and stats         */
osversion="z/VM 6.4"       /* OS version for enquries and stats         */
sysopname="Moshix"         /* who is the sysop for this chat server     */
sysopemail="moshix"        /* where to contact this systop            */
 
 
/* determine uptime of this machine  - WARNING OS DEPENDENCY!!!!!!    */
Parse Value Diag(8,'QUERY CPLEVEL') With ProdName .
Parse Value Diag(8,'QUERY CPLEVEL') With uptime  , . . .  .  .  .  . ipltime
/* say ProdName
say ipltime  */
/* global vars       */
 
loggedonusers = 0        /* online user at any given moment        */
highestusers = 0         /* most users online at any given moment  */
totmessages  = 0         /* total number of msgs sent */
otime = 0                /* overtime to log off users after n minutes */
starttime=mytime()       /* time this server started */
logline = " "            /* initialize log line      */
/* some simple logging  for stats etc        */
CALL     log('RELAY chat '||relaychatversion||' started. ')
 
 
/* init double linked list of online users   */
call @init
 
 
/* Invoke WAKEUP first so it will be ready to receive msgs */
/* This call also issues a 'SET MSG IUCV' command.         */
 
  'SET MSG IUCV'
  "WAKEUP +0 (IUCVMSG"
 
  'MAKEBUF'
/* In this loop, we wait for a message to arrive and       */
/* process it when it does.  If the "operator" types on    */
/* the console (rc=6) then leave the exec.                 */
 
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
/* handle all incomign messages and send to proper method */
   parse ARG userid,node,msg
    userid=strip(userid)
    node=strip(node)
    CurrentTime=Extime()
   umsg = translate(msg)  /* make upper case */
   updbuff=1
   SELECT                             /* HANDLE MESSAGE TYPES  */
      when (umsg = "/WHO") then
           call sendwho userid,node
      when (umsg = "/SYSTEM") then
            call systeminfo userid,node
      when (substr(umsg,5) = "/ROOM") then
           call changeroom userid,node, msg /* logged on user wants to change room*/
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
 
      otherwise
           call sendchatmsg userid,node,msg
        end
   if updBuff=1 then call refreshTime currentTime,userid,node
   call CheckTimeout currentTime
return
 
sendchatmsg:
/* what we got is a message to be distributed to all online users */
    parse ARG userid,node,msg
 
    if pos('/'listuser,$.@)>0 then do
      /*  USER IS ALREADY LOGGED ON */
 
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
 
            'TELL' userid 'AT' node 'Wecome to RELAY chat for z/VM v'relaychatversion
            'TELL' userid 'AT' node 'You are currently NOT logged on.'
            'TELL' userid 'AT' node '/HELP for help, or /LOGON to logon on'
            totmessages = totmessages + 3
       end
return
 
sendwho:
/* who is online right now on this system? */
   userswho = 0    /* counter for seen usres */
   parse ARG userid,node
   'TELL' userid 'AT' node 'List of currently logged on users:'
      do ci=1 to words($.@)
      entry=word($.@,ci)
      if entry='' then iterate
      parse value entry with '/'cuser'@'cnode'('otime')'
      'TELL' userid 'AT' node '> ' cuser'@'cnode
      totmessages = totmessages + 1
      userswho = userswho + 1
   end
  'TELL' userid 'AT' node '> Total online right now: 'userswho
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
  'TELL' userid 'AT' node '-> You are logged off now.'
  'TELL' userid 'AT' node '-> New total number of users: 'loggedonusers
   totmessages = totmessages + 2
return
 
 
 logonuser:
 /* add user to linked list */
 /* all users are logged on initially to room 0*/
    parse ARG userid,node
    listuser = userid"@"node
    if pos('/'listuser,$.@)>0 then do
       call log("List already logged-on: "||listuser)
      'TELL' userid 'AT' node '-> You are already logged on.'
      'TELL' userid 'AT' node '-> total number of users: 'loggedonusers
    end
    else do
       loggedonusers = loggedonusers + 1
          if loggedonusers < 0 then do
                  loggedonusers = 0
          end
 
       if highestusers < loggedonusers then highestusers = highestusers + 1
 
       call @put '/'listuser'('currentTime')'
       call log("List user added: "||listuser)
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
    'TELL' userid 'AT' node '-> NJE node name        : 'localnode
    'TELL' userid 'AT' node '-> Relay chat version   : 'relaychatversion
    'TELL' userid 'AT' node '-> OS for this host     : 'osversion
    'TELL' userid 'AT' node '-> Type of host         : 'typehost
    'TELL' userid 'AT' node '-> Location of this host: 'hostloc
    'TELL' userid 'AT' node '-> Time Zone of         : 'timezone
    'TELL' userid 'AT' node '-> SysOp for this server: 'sysopname
    'TELL' userid 'AT' node '-> SysOp email addr     : 'sysopemail
 
     totmessages = totmessages+ 7
return
 
 
sendstats:
/* send usage statistics to whoever asks, even if not logged on */
   parse ARG userid,node
    listuser = userid"@"node
    'TELL' userid 'AT' node '-> Total number of users: 'loggedonusers
    'TELL' userid 'AT' node '-> Hihgest nr.  of users: 'highestusers
    'TELL' userid 'AT' node '-> total number of msgs : 'totmessages
    'TELL' userid 'AT' node '-> Server up since      : 'starttime' 'timezone
 
     totmessages = totmessages+ 4
return
 
helpuser:
/* send help menu */
  parse ARG userd,node
  listuser = userid"@"node
 
 
   'TELL' userid 'AT' node 'Welcome to RELAY CHAT for z/VM, VM/ESA, VM/SP v'relaychatversion
   'TELL' userid 'AT' node '-------------------------------------'
   'TELL' userid 'AT' node '              '
   'TELL' userid 'AT' node '/HELP for this help'
   'TELL' userid 'AT' node '/WHO for connected users'
   'TELL' userid 'AT' node '/LOGON to logon to this chat room and start getting chat messages'
   'TELL' userid 'AT' node '/LOGOFF to logoff and stop getting chat messages'
   'TELL' userid 'AT' node '/STATS for chat statistics'
   'TELL' userid 'AT' node '/SYSTEM for info aobut this host'
   'TELL' userid 'AT' node '              '
   'TELL' userid 'AT' node '/ROOM 1-9 to join any room, default is room zero (0)'
   'TELL' userid 'AT' node ' messages with <-> are incoming chat messages...'
   'TELL' userid 'AT' node ' messages with   > are service messages from chat servers'
 
 
 
    totmessages = totmessages + 11
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
 
changeroom:
/* user who is alreayd logged on wants to change to a different room */
 parse ARG userid,node,msg

 listuser = userid"@"node 
 stripmsg = strip(msg)
 wantsroom = delword(stripmsg,1,1)  /* remove /ROOM from /ROOM 3 f.e., leaves only 3*/ 
 if ( datatype(wantsroom) <> "NUM")  | (c2d(wantsroom) < 0) | (c2d(wantsroom > 9 then do
     'TELL' userid 'AT' node '-> You have chosen an invalid rooom number (0-9'   
     return
else do
      /* check if user is logged on first*/
      if pos('/'listuser,$.@)>0 then do
            /*  USER IS ALREADY LOGGED ON */
      
                  do ci=1 to words($.@)
                     entry=word($.@,ci)
                     if entry='' then iterate
                     parse value entry with '/'cuser'@'cnode'#'room'('otime')'
                     /**** PETER how do I now change the room to wantsroom ??? */
                           'TELL' cuser 'AT' cnode '<> '-> you are now in room 'wantsroom
                  end
      
                  totmessages = totmessages+ 1
         end
            else do
               /* USER NOT LOGGED ON YET, LET'S SEND HELP TEXT */
      
                  'TELL' userid 'AT' node 'Wecome to RELAY chat for z/VM v'relaychatversion
                  'TELL' userid 'AT' node 'You are currently NOT logged on.'
                  'TELL' userid 'AT' node '/HELP for help, or /LOGON to logon on'
                  totmessages = totmessages + 3
            end
end
 return


CheckTimeout:
/*  check if user has not sent any message, automatic LOGOFF */
   arg ctime
   cj=0 /* save logons to remove, else logon buffer doesn't match  */
   do ci=1 to words($.@)
      entry=word($.@,ci)
      if entry='' then iterate
      parse value entry with '/'cuser'@'cnode'('otime')'
  /*  say cuser cnode ctime otime ctime-otime    */
      if ctime-otime> maxdormant then do  /* timeout per configuration */
         cj=cj+1
         $remove.cj=cuser','cnode
      end
   end
   do ci=1 to cj
      interpret 'call logoffuser '$remove.ci
      call log($remove.ci||'logged off due to timeout reached '||maxdormant|| ' minutes')
      loggedonusers = loggedonusers - 1
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
