# 
2 BITNET re-implementation of RELAY CHAT: One in Go and one in REXX  

This Go program operates a chat server on the BITNET NJE protocol network, of which HNET is one operating implementation as of Dec 2019. 

INSTALLATION
------------

git clone the repo
change the fifo path at the beginning of the program
go build chat.go
start

OPERATION
---------

you need to make sure that whatever receives messages for the NJE chat server will create a string like this:
USER@NODE:message

where USER is the sending user, NODE is the sending node, and message is the payload. 

that string nees to be written to a FIFO pipe, which chat.go reads and listens to. 

The commands for clients are:

/LOGON to add yourself to the distribution list for messages
/LOGOFF to remove yourself from distributions of messages
/WHO    who is logged on currently?
/STATS   some chat server stats
message  whatever you want to tell yourfriends on the channel



FUTURE FEATURES
---------------

- federation of relay chat servers
- persisting users unto a file
- MVS 3.8 port with BREXX
- chat rooms


RELAY EXEC 
----------

It's a re-implementation from scratch of the very famous RELAY chat written by  Jeff Kell (RIP) 
of the University of Tennessee at Chattanooga in 1985 using the REXX programming language.

efore BITNET Relay was implemented, any form of communication over BITNET required identifying the remote user and host.

Relay ran on a special ID using several BITNET hosts. To use it, a message was sent to a user ID called RELAY. 
The Relay program running on that user ID would then provide multi-user chat functions, primarily in the form 
of "channels" (chat rooms). The message could contain either a command for Relay (preceded by the 
popular "/" slash character command prefix, still in use today), or a 
message at the remote host (typically a mainframe computer).

Run this program in a service machine called RELAY on your z/VM, VM/ESA or VM/SP machine with NJE connections and anybody can
logon to your chat. Keep it runnign and disconnect the terminal from the VM



Hope you enjoy
Read more about RELAY CHAT and its history here: http://web.inter.nl.net/users/fred/relay/relhis.html

The RELAY structure here: https://en.wikipedia.org/wiki/BITNET_Relay

Tyical historical RELAY CHAT Session
------------------------------------

/SIGNUP robert harper
* Thank you for signing up, robert harper.
* Now use the /SIGNON <nickname> command to
* establish a nickname and to logon Relay.
/SIGN ON rob
Welcome to the Inter Chat Relay Network, Rob.
Your host is RELAY@FINHUTC (Finland).
Your last logon was at 08:39:23 on 03/17/89.
There are 67 users on 27 relays.
/HELP
**************** Relay Commands ***************
/Bye . . . . . . . . . . . . Signoff from Relay
/Channel <num> . . . . .Change to channel <num>
/Contact <host-nick> . .Show Relay contact info
/Getop . . . . . Try to summon a Relay operator
/Help. . . . . . . . . . . . . Prints this list
/Info. . . . . . . . . . . Send RELAY INFO file
/Invite <nick> . . .Invite user to your channel
/Links . . . . . . . . . . .Shows active relays
/List. . . . . . . . . . . List active channels
/Msg <nick> <text> . . . .Sends private message
/Nick <newnick>. . . . . . Change your nickname
/Names <channel> . . . . .Show users with names
/Rates . . . . . . . . . .Display message rates
/Servers <node>. . . . Show relays serving node
/Signon <nick> <channel> . . . .Signon to Relay
/Signon <nick>,SHIFT . . Forces uppercase shift
/Signon <nick>,UNSHIFT . Forces lowercase shift
/Signoff . . . . . . . . . . Signoff from Relay
/Signup <full name>. Signup or change full name
/Stats . . . . . . . . Display Relay statistics
/Summon <userid>@<node>. . Invite user to Relay
/Topic <subject> . . . . Topic for your channel
/Who <channel> . . . . Show users and nicknames
/WhoIs <nick>. . . . . . . .Identify a nickname 
/LINKS    
RELAY Version 01.24x0 Host RELAY@FINHUTC (Finland)
Relay  RELAY  @ CEARN   (  Geneva  ) ->  Finland
Relay  RELAY  @ DEARN   ( Germany  ) ->  Switzerland
Relay  RELAY  @ AEARN   ( Austria  ) ->  Germany
Relay  RELAY  @CZHRZU1A (  Zurich  ) ->  Geneva
Relay  RELAY  @ HEARN   ( Holland  ) ->  Geneva
Relay  RELAY  @TAUNIVM  ( TAUrelay ) ->  Geneva
Relay  RELAY  @EB0UB011 (Barcelona ) ->  Geneva
Relay  RELAY  @ ORION   (New_Jersey) ->  Geneva
Relay  RELAY  @ BITNIC  ( NewYork  ) ->  New_Jersey
Relay  RELAY  @JPNSUT10 (  Tokyo   ) ->  NewYork
Relay  RELAY  @ VILLVM  (Philadelph) ->  New_Jersey
Relay  RELAY  @NDSUVM1  (No_Dakota ) ->  New_Jersey
Relay  RLY   @CORNELLC (Ithaca_NY ) ->  New_Jersey
Relay  RELAY  @ UTCVM   (Tennessee ) ->  Pittsburgh
Relay  RELAY  @UIUCVMD  (Urbana_IL ) ->  Pittsburgh
Relay  RELAY  @CANADA01 ( Canada01 ) ->  Ithaca_NY
Relay  RELAY  @  AUVM   ( Wash_DC  ) ->  Va_Tech
Relay  RELAY  @ VTVM2   ( Va_Tech  ) ->  Ithaca_NY
Relay  RELAY  @UALTAVM  ( Edmonton ) ->  Canada01
Relay  RELAY  @NYUCCVM  (   Nyu    ) ->  New_Jersey
Relay  RELAY  @  UWF    (Pensacola ) ->  Va_Tech
Relay MASRELAY@  UBVM   ( Buffalo  ) ->  Ithaca_NY
Relay  RELAY  @CMUCCVMA (Pittsburgh) ->  Ithaca_NY
Relay  RELAY  @PURCCVM  (  Purdue  ) ->  Pittsburgh
Relay  RELAY  @UREGINA1 (Regina_Sk ) ->  Canada01
Relay  RELAY  @ GITVM1  ( Atlanta  ) ->  Tennessee 




November 2020
Moshix

