# relaychat
A BITNET re-implementation of RELAY CHAT 

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

/SET_TIMER to n minutes after which log me off
/MKCHANNEL XX create  a private channel
/CHANGE to XX chanenl
/DIRECT MESSAGE TO A PARTICULAR USER


Hope you enjoy
Dec 2019
Moshix

