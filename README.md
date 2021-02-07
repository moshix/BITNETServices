# Modern Re-Implementations of Traditional BITNET Services RELAY CHAT, TRICKLE, LISTSERV, ELIZA


<h1>RELAY CHAT Implementation</h1>



REXX CHAT 
---------

This is the actively maintained RELAY CHAT. 


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

1. /HELP
2. /WHO
3. /STATS
4. /SYSTEM
5. /DM       (direct message to a user)
6. /SHUTDOWN (for sysopt only and requires password)
7. /ROOM.    (go into room X)



REXX VERSION INSTALLATION
-------------------------

This program runs on z/VM, VM/ESA 2.x and VM/SP6. No version earlier than VM/SP rel6 is supported currently.  

1. Upload RELAY EXEC to a VM account named RELAY with permissions G. 

2. configure the first few environemnt-specific variables at the top of the program. Most important are NJE node name, time zone and sysop name

3. for VM/ESA and up configure the compatibility variable to 2 .For VM/SP6, use compatibility=1

4. Give your RELAY virtual machine the necessary class to enable it to issue this command: 
   defaults set tell msgcmd msgnoh 
   
5. Make sure your RSCS CONFIG has class B and the option MSGNOH enabled

6. start with "RELAY" and disconnect the terminal



<br><br>

</h>Shut it down remotely with the password you configured in the environment-specific variables. 

<br><br>
RELAY CHAT on MVS 3.8
=====================
<br>
An MVS 3.8 version of RELAY CHAT is also availble in this repo. 
<br><br><br><br>

FUTURE FEATURES
---------------
<br><br>
- Federation of relay chat servers                  [DONE]<br>
- Loop detection                                    [DONE]<br>
- Message throttling                                    [DONE]<br>
- Persisting users unto a file for crash recovery<br>
- MVS 3.8 port with BREXX[DONE]<br>
- Chat rooms [DONE]<br>
<br><br>


RELAY CHAT History
------------------

Read more about RELAY CHAT and its history here: http://web.inter.nl.net/users/fred/relay/relhis.html
<br><br>

The original RELAY description can be found here: https://en.wikipedia.org/wiki/BITNET_Relay

<br><br>



<h1>TRICKLE FILE SERVER</h1>

<h1>ELIZA</h1>
<br>
ELIZA/NJE is available in MVS 3.8 and VM versions. This is a single-tenant implementation, ie only one NJE user at a time can enter into a session with ELIZA/NJE. <br>The commands are the same for both versions:
<br>
/AVAILABLE     check if eliza is available for a session 
/LOGON         start a session
/LOGOFF        finish a session
/WHO           who is in a session currently
/SYSTEM        information about this particular node
/STATS         some stats
/HELP          HELP menu
<br><br>

ORIGINAL RELEASE: November 2020<br>
UPDATED: January 29, 2021<br>
Moshix

