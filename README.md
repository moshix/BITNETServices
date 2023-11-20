[![Discord](https://img.shields.io/discord/423767742546575361.svg?label=&logo=discord&logoColor=ffffff&color=7389D8&labelColor=6A7EC2)](https://discord.gg/vpEv3HJ)
<a href="https://hits.seeyoufarm.com"><img src="https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2Fmoshix%2FBITNETServices&count_bg=%2379C83D&title_bg=%23555555&icon=&icon_color=%23E7E7E7&title=hits&edge_flat=false"/></a>
[![View SBOM](https://img.shields.io/badge/sbom.sh-viewSBOM-blue?link=https%3A%2F%2Fsbom.sh%2F0ff42f94-545a-4ffe-a7d0-4da9d6b24c2b)](https://sbom.sh/0ff42f94-545a-4ffe-a7d0-4da9d6b24c2b)
<br>

# Modern Implementations of Traditional BITNET Services RELAY CHAT, TRICKLE, LOOKUP, LISTSERV, ELIZA, QBIT, MTRAP, YWAKEUP, NSCAN, IUCVTRAP


<h1>RELAY CHAT Implementation</h1>


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
7. /USERS
8. /HISTORY
9. /VERSION
10. /LOGON
11. /LOGOFF
12. /BENCHMARK



INSTALLATION
------------

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
- Federation of relay chat servers                  <br>
- Loop detection                                    [DONE]<br>
- Message throttling                                    [DONE]<br>
- Persisting users unto a file for crash recovery<br>
- MVS 3.8 port with BREXX[DONE]<br>
- recent chat history upon login [DONE]<br>
- system benchmarking for user reference and flagellation [DONE]<br>
<br><br>

relay.bash for Linux
====================
<br>
This is an implementation of relay chat for funetnje, or #unixnje or Sine Nomine Associates NJE NJE serves on Linux. 
<br>
It does all the things that RELAY CHAT on MVS 3.8 does, including throttling, loop detection and user to user direct messagging. <br>
It requires bash v4.2 or greater. In this source code I use bash v5.10 but it's equivalen to v4.2.69 for the purposes of this program. 

<br><br>
RELAY CHAT History
------------------

Read more about RELAY CHAT and its history here: http://web.inter.nl.net/users/fred/relay/relhis.html
<br><br>

The original RELAY description can be found here: https://en.wikipedia.org/wiki/BITNET_Relay

<br><br>



<h1>TRICKLE FILE SERVER</h1>
<br>
Here is the current help file.
<pre>
trickle /help
                       
Ready
                                                
 From FILESERV:   TRICKLE/NJE v0.1
 From FILESERV:
 From FILESERV:   /HELP   for this help menu
 From FILESERV:   /PDGET  dirname.file to receive a file in your spool
 From FILESERV:   /DIR    to see contents a directory / being top level dir
 From FILESERV:   /TREE   to see the full tree of directories and files
 From FILESERV:   /SUB    to subscribe to chagnes to a directory
 From FILESERV:   /STATS  for TRICKLE stats
 From FILESERV:   /SYSTEM for information about this TRICKLE server
 From FILESERV: Execution time: 0.126s excluding net transmission time
</pre>
<br><br>

<h1>ELIZA</h1>
<br>
ELIZA/NJE is available in MVS 3.8 and VM versions. This is a single-tenant implementation, ie only one NJE user at a time can enter into a session with ELIZA/NJE. <br>The commands are the same for both versions:
<br>
<pre>
eliza /help
You: /help                             ...
Ready;
   _____ _     _____ ______  ___
  |  ___| |   |_   _|___  / / _ \      GUARANTEED NO-COVID
  | |__ | |     | |    / / / /_\ \      ___   _    ___ _____
  |  __|| |     | |   / /  |  _  |     / / \ | |  |_  |  ___|
  | |___| |_____| |_./ /___| | | |    / /|  \| |    | | |__
  \____/\_____/\___/\_____/\_| |_/   / / | . ` |    | |  __|
    for z/VM, VM/ESA, VM/SP MVS/3.8 / /  | |\  |/\__/ / |___
                                   /_/   \_| \_/\____/\____/
 /HELP   for this help
 /AVAILABLE to enquire about available. ALWAYS ENQUIRE FIRST!
 /LOGON  to start a session with Eliza and feel better quickly
 /LOGOFF to logoff and stop your session with Eliza
 /STATS  for ... you guessed it ...statistics!
 /SYSTEM for info about this host
  
  messages with  -> are dialogues from Eliza

</pre>
<br><br>
<h1>Python Simple Chat Server</h1>
<br>
This chat server is named simplechat, but it is anything but simple. It's actually quite powerful. It is compatible with every Pyton 3.x without other package requirements and can be a handy ad-hoc chat server that scales well to thousands of users. Check it out. 
<br>
Now also with SSL and pub/priv key support!
<br><br>

<h1>IUCVTRAP</h1>
<br>
This is a IUCVTRAP implementation for VM/SP and VM/XA. It assembles fine and it is a better WAKEUP for VM. XYZZY can be made to work with this. Check out the source. <br>
Included is also iucvtrap_VMsp3.vmarc which is a version that assembles cleanly on VM/SP r3-r5. 
<br><br>Find BITNET goodies in the VM Workshop tape collection http://www.vmworkshop.org/1986/86tools.shtml
<br><br>
ORIGINAL RELEASE: November 2020<br>
UPDATED:November 19, 2023 - Milan<br>
Moshix

