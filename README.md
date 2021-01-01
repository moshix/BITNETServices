# 2 BITNET Implementations of RELAY CHAT: One in Go and one in REXX  

This Go program operates a chat server on the BITNET NJE protocol network, of which HNET is one operating implementation as of Dec 2019. 

GO VERSION INSTALLATION
-----------------------

git clone the repo
change the fifo path at the beginning of the program
go build chat.go
start

GO VERSION OPERATION
--------------------

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





RELAY EXEC 
----------

It's a re-implementation from scratch of the very famous RELAY chat written by  Jeff Kell (RIP) 
of the University of Tennessee at Chattanooga in 1985 using the REXX programming language.

Before BITNET Relay was implemented, any form of communication over BITNET required identifying the remote user and host.

Relay ran on a special ID using several BITNET hosts. To use it, a message was sent to a user ID called RELAY. 
The Relay program running on that user ID would then provide multi-user chat functions, primarily in the form 
of "channels" (chat rooms). The message could contain either a command for Relay (preceded by the 
popular "/" slash character command prefix, still in use today), or a 
message at the remote host (typically a mainframe computer).

Run this program in a service machine called RELAY on your z/VM, VM/ESA or VM/SP machine with NJE connections and anybody can
logon to your chat. Keep it runnign and disconnect the terminal from the VM

Commands supported by RELAY EXEC:

/HELP
/WHO
/STATS
/SYSTEM
/DM
/SHUTDOWN
/ROOM
/SHOUT


REXX VERSION INSTALLATION
-------------------------

This program runs on z/VM, VM/ESA 2.x and VM/SP6. 

1. Upload RELAY EXEC to a VM account named RELAY with permissions G. 

2. configure the first few environemnt-specific variables at the top of the program. Most important are NJE node name, time zone and sysop name

3. for VM/ESA and up configure the compatibility variable to 2 .For VM/SP6, use compatibility=1

4. Give your RELAY virtual machine the necessary class to enable it to issue this command: 
   defaults set tell msgcmd msgnoh 
   
5 Make sure your RSCS CONFIG has class B and the option MSGNOH enabled

6. start with "RELAY" and disconnect the terminal




shut it down remotely with the password you configured in the environment-specific variables. 



FUTURE FEATURES
---------------

- federation of relay chat servers
- persisting users unto a file
- MVS 3.8 port with BREXX
- chat rooms

Hope you enjoy
Read more about RELAY CHAT and its history here: http://web.inter.nl.net/users/fred/relay/relhis.html

The RELAY structure here: https://en.wikipedia.org/wiki/BITNET_Relay


November 2020
Moshix

