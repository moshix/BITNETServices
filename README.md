[![Discord](https://img.shields.io/discord/423767742546575361.svg?label=&logo=discord&logoColor=ffffff&color=7389D8&labelColor=6A7EC2)](https://discord.gg/vpEv3HJ)
<a href="https://hits.seeyoufarm.com"><img src="https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2Fmoshix%2FBITNETServices&count_bg=%2379C83D&title_bg=%23555555&icon=&icon_color=%23E7E7E7&title=hits&edge_flat=false"/></a>
[![View SBOM](https://img.shields.io/badge/sbom.sh-viewSBOM-blue?link=https%3A%2F%2Fsbom.sh%2F0ff42f94-545a-4ffe-a7d0-4da9d6b24c2b)](https://sbom.sh/0ff42f94-545a-4ffe-a7d0-4da9d6b24c2b)
<br>

# Modern Implementations of Traditional BITNET Services


In this repository you find out the most important software to run a fully-featured NJE BITNET network, like the HNET NJE network. 

The main servers are RELAY CHAT, TRICKLE, LOOKUP, LISTSERV, ELIZA.   

XYZZY is a chat client in REXX for VM/SP and z/VM. 


And QBIT, QUSER, MTRAP, YWAKEUP, NSCAN, IUCVTRAP, SUPERMSG, CLRSCRN,  XYZIUCV are tools to ether triap NJE messages or handle them.   


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

This program runs on z/VM, VM/ESA 2.x and VM/SP R4. No version earlier than VM/SP R4 is supported currently.  

1. Upload RELAY EXEC to a VM account named RELAY with permissions G. 

2. configure the first few environemnt-specific variables at the top of the program. Most important are NJE node name, time zone and sysop name

3. for VM/ESA and up configure the compatibility variable to 2 .For VM/SP R4, use compatibility=1

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
Included is also iucvtrap_VMsp3.vmarc which is a version that assembles cleanly on VM/SP r3-r5. <br><pre>
Use the IUCVTRAP command to trap specified CP and/or CMS responses
for subsequent viewing or stacking onto the CMS program stack.
 
syntax: IUCVTRAP { ON 
                 | OFF
                 | TYPE nnn
                 | GRAB <( WAIT  <)> > }
                 | EXTRACT <( WAIT  <)> > }
 
Use the CP SET command to select the responses to be intercepted
by IUCVTRAP. The following CP SET commands have explanations provided:
 
 CP SET MSG IUCV     - specifies interception of incoming CP MESSAGES.
 CP SET WNG IUCV     - intercept incoming CP WARNING messages.
 CP SET EMSG IUCV    - intercept Error messages.
 CP SET ACNT IUCV    - intercept Accounting messages.
 CP SET IMSG IUCV    - intercept Informational messages.
 CP SET SMSG IUCV    - intercept incoming Special Messages.
 CP SET VMCONIO IUCV - intercept CMS generated console output.
 CP SET CPCONIO IUCV - intercept CP generated console output.
 
Type HELP CP SET for more information on the above mentioned command.
 
When any of the above options are set to IUCV, IUCVTRAP may be used
to intercept and save the trapped text in an internal stack. This
stack can be interrogated with the IUCVTRAP TYPE  command, or
the IUCVTRAP GRAB <( WAIT <)> > command. IUCVTRAP TYPE will dump
the entire contents of the internal stack to the CMS console. The nnnn
operand specifes the number of lines to be typed at the console. This
is useful if there are many internally stacked lines.
 
IUCVTRAP GRAB will stack LIFO the first trapped message that appears
on the internal queue. Using the WAIT option, an exec can be used to
wakeup whenever a message is received. If the WAIT option is not used
and a GRAB is attempted with an empty internal stack, the message
"* No messages available" is stacked. WAIT followed by a 3 digit number
specifying a wait interval (in seconds) may also be used. When the timer
expires, a return code 3 will be returned. If the WAIT is ended by a
console attention, a return code 2 will be returned.
 
IUCVTRAP ON initializes IUCVTRAP. IUCVTRAP ON ALL initializes IUCVTRAP
for use with all classes of IUCV messages.
 
IUCVTRAP EXTRACT works the same as GRAB, except that the message is
placed in a EXEC2 or REXX variable named IUCVMSG.
 
A full 255 characters will be stacked for each stacked line,
although EXEC2 may only access
the first 130 characters of each line.
Rexx may access all 255.
</pre>
<br><br>Find BITNET goodies in the VM Workshop tape collection http://www.vmworkshop.org/1986/86tools.shtml
<h1>SUPERMSG</h1>
<br>
This command retreives data from the IUCV  *MSG system service. Through
judicious use of options on the CP SET command, some or all virtual machine
console traffic can be directed to the *MSG system service and subsequently
processed by an exec or program.
Also handels output of virtual machine commands (e.g.  LISTDS, MACLIB, TSTLIB
etc.) which do not provide a stack option.<br>
Author: Barry Leiba<br>
 IBM Corporation, Building 181, 2p23, F.S.D. 18100 Frederick Pike<br>
 Gaithersburg, MD. 20879<br>
    SUPERMSG SCRIPT   B1 V         68         40          2<br>
    SUPERMSG MODULE   B2 V       3832          3          4<br>
    SUPERMSG MACLIB   B2 F         80        454         36<br>
    SUPERMSG LISTING  B1 F        121       3445        408<br>
    SUPERMSG HELPCMS  B1 F         80        211         17<br>
    MH       EXEC     B2 V        119        144          4<br>
    CPSET    EXEC     B2 V         53         29          1<br>
    SUPERMSG ASSEMBLE B1 F         80        634         50<br>
Date: 86 04 08<br>
<h1>PHONE</h1>
<br>
<pre>
The PHONE command provides a messaging environment suitable for on-line
conversation.  Both incoming and outgoing messages are stored in a
buffer which scrolls as it grows to exceed the dimensions of the screen.
 
The format of the PHONE command is:
 
-------------------------------------------------------------------------------
|           |                                                                 |
|           |  +-                     -+                                      |
|  PHONE    |  | (nickname) | (userid) |                                      |
|           |  +-                     -+                                      |
|           |                                                                 |
-------------------------------------------------------------------------------
 
This program offers a full screen environment capable of sending
messages to both local users and those on other systems.  In addition to
its ability to send messages to one of three users, PHONE features the
following options: automatic logging to disk of all messages, a provision
for modifying your NAMES file, and the help facility you are presently
using.  These and all other functions are PF-key driven as follows:
 
PF01: Invokes the help facility and displays the panel you are
presently reading.  If, however, the word 'pf' is on the command line,
the settings of the function keys will be displayed in the message area,
and the help screen will not be invoked.
 
PF02: Places you in the CMS subset environment where you may execute
CMS and CP commands.  Incoming messages are still trapped by PHONE, and
will be displayed upon your exit from CMS subset.  However, PHONE will
only trap 255 messages.  Any messages in excess of this number which
arrive while you are in subset will be displayed on your screen in the
normal (CMS) fashion.
 
PF03: Will have you exit the PHONE full screen environment and
return to CMS.
 
PF04: Will toggle the PHONE TAP.  When the phone tap is on, all
messages, whether incoming or outgoing, are written into a disk file
called 'PHONE TAP A'.  The current setting of the phone tap toggle is
displayed in the upper lefthand corner of the screen.  If the tap is
active, the word 'Tap' is displayed there.
 
PF05: Assumes that a nickname or userid is present on the command
line, in one of the following forms: 'nickname', 'userid',
'userid@nodeid', or 'userid AT nodeid'.  If the nickname or userid is
alone on the command line, it is entered into the nickname list
(displayed in the top right-hand corner of the screen), and the userid
and nodeid are displayed left of the command line (if a nickname was
given, your names file will be searched for the corresponding userid and
nodeid).  The active nickname or userid is the leftmost, highlighted
entry in the nickname list.  This user will receive whatever is typed
on the command line.  If the nickname or userid is followed by text, a
single message will be sent to this user who will not be added to the
nickname list.
 
PF06: Rotates the 3 userids in the nickname list, allowing you to
quickly switch from one to the other.  Keep in mind that the active
nickname or userid is the leftmost, highlighted one.
 
PF07: Having set scroll off, will move back in the message buffer
maintained by PHONE.  The last one hundred messages are remembered.
If less than that number have been received, you will back up only as
far as the oldest message.  To return to the end of the buffer and
resume reception and scrolling of incoming messages, use PF12 to toggle
the scroll setting.
 
PF08: Will move forward in the message buffer described above.
This key will not alter the setting of the scroll toggle.  If presently
scrolling, this key is ignored.
 
PF09: Will execute the CMS command 'NAMES', placing you in an full
screen environment suitable for the creation and modification of
nicknames.  For more information, type 'HELP NAMES'.
 
PF10: Will retrieve your last message line.  Repeated invocation
of this function will retrieve up to the last four message lines, and
then loop back to the first.
 
PF11: Will toggle the setting that determines whether the node IDs
associated with the displayed messages are to be visible.  When these
are not displayed, the screen may contain more messages.  An indicator
of the current setting of this toggle is located to the left of the word
'P H O N E' on the top line of the screen.
 
PF12: Will toggle the scroll setting.  When scrolling is off, the
messages displayed on your screen will remain undisturbed (except for
movement within the message buffer using PF07 (back) and PF08 (forward))
until scrolling is resumed.  When this happens, your screen will display
the most recent messages.  An indicator of the current scroll setting
is located immediately to the left of the word 'P H O N E' on the top
line of the screen.
 
PA2: Will clear the message buffer; the screen will become blank.
 
 
To avoid the display of the Function Key layout upon entering
phone, issue the following command from CMS:
 
GLOBALV SELECT PHONE SETP PFKMSGS OFF
 
Return^codes:       rc =    1 => IUCV error.
                    rc =    2 => I/O error to the terminal.
                    rc =    3 => I/O error to 'PHONE TAP A' file.
                    rc =    4 => IDENTIFY command error.
                    rc =    5 => HNDIUCV macro error.
                    rc =  159 => insufficient memory.
</pre>
<br><br>
ORIGINAL RELEASE: November 2020<br>
UPDATED:February 8, 2023- Milan, Italy  <br>
Moshix

