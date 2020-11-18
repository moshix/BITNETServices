/* REXX */
/* (C) COPYRIGHT 2019 BY MOSHIX and Peter Jacob
   chat, a Rexx CMS client program to connect to the RELAY chat server
   Apache license

   invoke with chat

   start with /logon    

   everythng you type after chat  be sent to all participants
   you will see other people's text message

VERSION 0.4
*/

parse arg  arg1
uarg1 = translate(arg1)

if ARG() = 0 then
 DO
   say ' '
   say 'RELAY Chat v0.4'
   SAY 'OPTIONS: /LOGON     /LOGOFF     /WHO    /STATS       MESSAGE'
   SAY ' '
 EXIT
end
'SET RDYMSG SMSG'

SELECT
WHEN uarg1="/LOGON" THEN
  do
    'TELL relay at sevmm1 /logon'
end

WHEN uarg1="/LOGOFF" THEN
  do
    'TELL relay at sevmm1 /logoff'
end

WHEN uarg1="/WHO" THEN
  do
    'TELL relay at sevmm1 /who'
end


OTHERWISE
do
  IF uarg1 = "" then
  do
   say 'you need to supply a command or a chat message'
   exit
  end
  'TELL relay AT SEVMM1' arg1
 exit
end
end


 SAY '  '
 SAY "RELAY CHAT CLIENT V0.4                               "
 SAY ' '

EXIT
