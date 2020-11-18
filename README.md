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

It's a re-implementation from scratch of the very famous RELAY chat written by Mr. Kell (RIP) 

Run it in a service machine called RELAY on your z/VM, VM/ESA or VM/SP machine with NJE connections and anybody can
logon to your chat. Keep it runnign and disconnect the terminal from the VM



Hope you enjoy


November 2020
Moshix

