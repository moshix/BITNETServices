#!/opt/homebrew/bin/python3.9
import socket
import threading
import random
import signal
import sys
import string
import time
import datetime
from dataclasses import dataclass


# Copyright 2023 by moshix
# License: All rights restricted. You may not copy, use, or re-use parts or all of this code and algorithms  without my written permission.
# v 0.1  humble beginnings
# v 0.2  Added random names
# v 0.3  Greet user individually
# v 0.4  Inform other users that a certain users has disconnected, then delete from names{}
# v 0.5  Handle command /who
# v 0.6  Handle /stats
# v 0.7  Handle /help
# v 0.8  Now get host and port from command line optionally
# v 0.9  Change nick name with /nick
# v 0.91 Show message of the day with /motd
# v 1.0  DM between users: bug!!! /nick does not correclty change clients dictionary
# v 1.1  Use colors for DM, and response to commands
# v 1.2  Make sure new /nick is unique and otherwise reject it!
# v 1.3  Inform all online users of user who changed nick name!
# v 1.4  Random sentences to inform of new users
# v 1.5  Make random names witha space and set timeout for sockets
# v 1.6   /logoff to get out
# v 1.7  show time stamp for incoming messages
# v 1.8  Fix for Windows compatibility and make IP address reuse turned on
# v 1.9  Collect more per user information in a struct chat_user
# v 2.0  Re-organize into more functions (for send, for search of users etc)
# v 2.1  Show more info per user, and start moving to dataclass in chat_user structure for more services
# v 2.3  /away to set status away from keyboard
# v 2.4  TODO SSL comms
Version = "2.3"

class bcolors:
      HEADER = '\033[95m'
      WHITE = '\033[95m'
      OKBLUE = '\033[94m'
      BLUE = '\033[94m'
      OKCYAN = '\033[96m'
      CYAN = '\033[96m'
      OKGREEN = '\033[92m'
      GREEN = '\033[92m'
      WARNING = '\033[93m'
      YELLOW = '\033[93m'
      FAIL = '\033[91m'
      RED = '\033[91m'
      ENDC = '\033[0m'
      UNDERLINE = '\033[4m'


##@dataclass
##class House:
##    city: str
##    street: str
##    price: int
##
##
##houseArray = []
##for index in range(3):
##    house = House(city = 'Beijing', street = '1st street', price = 1000)
##    houseArray.append(house)
##
##
##for item in houseArray:
##    if item.city == 'Beijing':
##        print(item)
##



#------------------------------------------------------------------------
# Set up function to handle client messages
def handle_client(client_socket):
    global chat_user
    global chat_userArray
    global totmsg
    global maxusers
    global currentusers
    global started
    global helpmsg
    global Motd
    nickExists = "False"  # for dupblicate nickname checking
    try:
        while True:
            # Receive message from client

            # some stats keeping
            currentusers = 0
            for toBroadcast, data in clients.items():
                 currentusers= currentusers + 1
                 if maxusers < currentusers:
                     maxusers = maxusers +1

            whosent = 0
            received = client_socket.recv(1024)
            if(received == b'' or received == b'xfff4'):
                print(str(user) + " has disconnected")
                client_socket.sendall(b"hello")
                client_socket.close()
                break
            #message = received.decode('ascii', "ignore")
            message = received.decode('ascii', "backslashreplace")
            #message = received.decode('ascii', "replace")
            #message = received.decode('ascii')
            if (message == "����"):
                print(str(user) + "sent a Ctrl-C")
                logoffmsg= bcolors.YELLOW + str(datetime.datetime.now())[11:22] + "Ok, then. See you soon! " +  bcolors.ENDC  + newline
                whosent.close()
                client_socket.close()
                break
            totmsg = totmsg + 1
            stripmsg=message.strip() #strip of newline
            whosent = client_socket
            user = clients[client_socket]["name"]

            if stripmsg != "":
               print(str(datetime.datetime.now())[11:22] + " User: ",user, " wrote: ", message) # for console
            formatmsg = user + "> " + message
            #print ("Debug: msg: " + stripmsg + newline)
            update_user_lastSeen(client_socket)

            # handle  help request
            if stripmsg[:5] == "/Help" or stripmsg[:5] == "/help":
                totmsg = totmsg + 1
                whosent.send(helpmsg.encode('ascii'))
                continue

           # handle message of the day (motd) request
            if stripmsg[:4] == "/Mot" or stripmsg[:4] == "/mot":
                totmsg = totmsg + 1
                whosent.send(Motd.encode('ascii'))
                continue

            # handle version request
            if stripmsg[:4] == "/Vers" or stripmsg[:4] == "/ver":
                totmsg = totmsg + 1
                versionmsg = str(bcolors.CYAN + "Moshix Chat Server is currently running Version: ") + str(Version) + bcolors.ENDC + newline
                whosent.send(versionmsg.encode('ascii'))
                continue

            # handle stats request
            if stripmsg[:6] == "/stats" or stripmsg[:5] == "/Stats":
                totmsg = totmsg + 1
                strtotmsg = str(totmsg)
                strcurrentusers = str(currentusers)
                strmaxusers = str(maxusers)
                strstarted = str(started)
                statsmsg1 = str(bcolors.CYAN +"Chat server up since: " + strstarted[:19] + bcolors.ENDC + newline)
                statsmsg2 = str("Total messages: " + strtotmsg + " - current users: " + strcurrentusers + " - Max users: " + strmaxusers + bcolors.ENDC + newline)
                whosent.send(statsmsg1.encode('ascii'))
                whosent.send(statsmsg2.encode('ascii'))
                continue


            # handle to change nick name with /nick
            if stripmsg[:4] == "/nic" or stripmsg[:4] == "/Nic":
                print ("Debug: Entered /nick function ")
                wordCount = len(stripmsg.split())
                #print ("Debug: /nick number of words: ", wordCount)

                if wordCount < 2:
                    totmsg = totmsg + 1
                    errormsg=bcolors.YELLOW  + "You need to provide a one word nickname, like:  /nick JiffyLube. Retry. " +  bcolors.ENDC  + newline
                    whosent.send(errormsg.encode('ascii'))
                else:
                    #find out if nick already exists
                    nick = stripmsg.split()[1]
                    strnick = str(nick)
                    #print(bcolors.GREEN + "Debug: in else: strnick: : " + strnick + bcolors.ENDC)

                    # does this nick exist alrady? let's loop thru all clients to find out
                    for client_socket, name in clients.items():
                        #print(bcolors.GREEN + "Debug: INSIDE search looop! strnick: : " + strnick + bcolors.ENDC)
                        #print(bcolors.GREEN + "Debug: name: : " + name  + bcolors.ENDC)
                        if clients[client_socket]["name"]  == strnick:
                            #print(bcolors.WARNING +"Debug: Found client socket for nick: " + str(clients[client_socket]) + bcolors.ENDC)
                            nickExists = "True" #this nickname already exists!
                        else:
                            nickExists = "False"

                    if nickExists == "False":
                        update_user_nick(client_socket, strnick)
                        clients[client_socket]["name"] = strnick
                        print(bcolors.CYAN + str(datetime.datetime.now())[11:22] + " User: " + str(user) + " has changed name to: " +strnick + bcolors.ENDC) #also print on console
                        confirm = bcolors.CYAN + "Your nick has been changed to: " + bcolors.WHITE + strnick +  bcolors.ENDC + newline
                        totmsg = totmsg + 1
                        whosent.send(confirm.encode('ascii'))

                        # now inform all users of name change
                        for toBroadcast, data in clients.items():
                            if toBroadcast != whosent:
                               totmsg = totmsg + 1
                               nickchangemsg = bcolors.CYAN + str(datetime.datetime.now())[11:22] + " User: " + str(user) + " has changed nickname to: " + bcolors.GREEN + strnick + bcolors.ENDC + newline
                               toBroadcast.send(nickchangemsg.encode('ascii'))
                    else:
                        confirm = bcolors.WARNING + "No can  do. This nickname already exists... " + bcolors.WHITE + strnick +  bcolors.ENDC + newline
                        totmsg = totmsg + 1
                        whosent.send(confirm.encode('ascii'))
                    continue

                # handle send direct message to a particular user
            if stripmsg[:3] == "/dm" or stripmsg[:3] == "/Dm":
                wordCount = len(stripmsg.split())

                if wordCount < 2:
                    print(bcolors.WARNING +"Debug: less than 2 wordcount in /DM" + bcolors.ENDC)
                    totmsg = totmsg + 1
                    errormsg=bcolors.YELLOW + "You did not provide a nickname.  Retry. " +  bcolors.ENDC  + newline
                    whosent.send(errormsg.encode('ascii'))
                    continue
                if wordCount < 3:
                    #print(bcolors.WARNING +"Debug: less than 3 wordcount in /DM" + bcolors.ENDC)
                    totmsg = totmsg + 1
                    errormsg= bcolors.YELLOW + "You did not provide a DM.  Retry. " +  bcolors.ENDC  + newline
                    whosent.send(errormsg.encode('ascii'))
                else:
                    #print(bcolors.WARNING +"Debug: 3 or more words found in /dm" + bcolors.ENDC)
                    nick  = stripmsg.split()[1]
                    strnick = str(nick)
                    #print(bcolors.WARNING +"Debug: target of DM: " + strnick + newline)
                    # get DM payload
                    dmCount = len(stripmsg.split()) # how many words in total message sent by requester
                    dmsplit = stripmsg.split() # stripomsg split into words
                    # finds client_socket from name
                    for client_socket, name in clients.items():
                        # print(bcolors.OKGREEN + "Debug: nick: " + str(name) + "  client_socket: ", str(client_socket) + " "  + bcolors.ENDC)
                        #print(bcolors.OKGREEN + "Debug: strnick: : " + strnick + bcolors.ENDC)
                        #print(bcolors.OKGREEN + "Debug: name: : " + name  + bcolors.ENDC)
                        if clients[client_socket]["name"]  == strnick:
                            #print(bcolors.WARNING +"Debug: Found client socket for nick: " + str(clients[client_socket]) + bcolors.ENDC)
                            toDm=client_socket
                        else:
                            toDm=0

                    if toDm != 0:
                        #print(bcolors.WARNING +"Debug: Found client socket for nick: " + str(clients[client_socket]) + bcolors.ENDC)
                        totmsg = totmsg + 2 # one for confirmation and one with DM
                        confirm = "Message to sent to" + str(strnick) + newline
                        dm = dmsplit[2:] # get everything exepct first two words: /DM nick ..
                        strdm = ' '.join(dm)
                        #print(bcolors.WARNING + "Debug: payload: " + strdm + bcolors.ENDC)
                        whosent.send(confirm.encode('ascii'))
                        DMmsg=bcolors.GREEN + str(datetime.datetime.now())[11:22] + " -" + bcolors.YELLOW + "DM-  " + bcolors.GREEN + "from " + str(user) + bcolors.RED + " > " + strdm + bcolors.ENDC + newline
                        toDm.send(DMmsg.encode('ascii'))
                    else:
                        totmsg = totmsg + 1
                        confirm = bcolors.YELLOW + "Your DM cannot be sent. Nick not existing or logged out meanwhile. " +  bcolors.ENDC  + newline
                        whosent.send(confirm.encode('ascii'))
                    continue


            # send list of logged in users to requesting client
            if stripmsg[:6] == "/users/" or stripmsg[:4] == "/who" or stripmsg[:4] == "/Who":
                counter = 0
                for toBroadcast, data in clients.items():
                    totmsg = totmsg + 1
                    counter = + counter + 1
                    strcounter = str(counter)
                    listuser = clients[toBroadcast]["name"]
                    for item in chat_userArray:
                       if item.socket == client_socket:
                          last = item.lastSeen
                          intime = datetime.datetime.now() - last
                          #intimemin = divmod(intime.total_seconds(), 60) / 1000000
                          #strlast = str(intimemin)
                    detail = str(bcolors.CYAN + strcounter + " -  Last Seen: " + str(last)[11:19] + "  - " + listuser + " : Status= "+ item.Status + " " + bcolors.ENDC  + newline)
                    whosent.send(detail.encode('ascii'))
                continue

            if stripmsg[:7] == "/logoff" or stripmsg[:7] == "/LOGOFF":
              if client_socket in clients:
                 logoffmsg= bcolors.YELLOW + str(datetime.datetime.now())[11:22] \
                  + "Ok, then. See you soon! " +  bcolors.ENDC  + newline
                 totmsg = totmsg + 1
                 whosent.send(logoffmsg.encode('ascii'))
                 whosent.close()
                 #del clients[client_socket]
                 # remove client from all data structures
                 del_user(client_socket)
                 # now inform all users of name change
                 for toBroadcast, data in clients.items():
                     if toBroadcast != whosent:
                        totmsg = totmsg + 1
                        usergonemsg = bcolors.CYAN + str(datetime.datetime.now())[11:22] + \
                        "User: " + str(user) + " has left. " + bcolors.GREEN + strnick + bcolors.ENDC + newline
                        toBroadcast.send(usergonemsg.encode('ascii'))
              continue

            # nextgen handling function... see how clean it is??
            if stripmsg[:5] == "/away" or stripmsg[:5] == "/Away":
               set_user_away(client_socket, user)
               continue



            #________________________________________________________________________________________
            #[                                                                                       ]
            # Broadcast message to all clients
            if stripmsg != "":
              formatmsg= bcolors.GREEN + str(datetime.datetime.now())[11:22]  + " - " +str(user) \
              + bcolors.RED + " > " + bcolors.BLUE + stripmsg + newline + bcolors.ENDC
              #for toBroadcast, data in clients.items():
              #    if toBroadcast != whosent:
              

              for item in chat_userArray:
                      if item.socket != whosent:
                         totmsg = totmsg + 1
                         item.socket.send(formatmsg.encode('ascii'))
            #[                                                                                       ]
            #________________________________________________________________________________________



    except (ConnectionResetError, OSError):
        print("Client connetion reset")
    finally:
        if client_socket in clients:
            del clients[client_socket]
# end of handle_cient function
#------------------------------------------------------------------------

def set_user_away(client_socket, user):
  global clients
  global chatuser_Array
  global chat_user
  for item in chat_userArray:
       if item.socket == client_socket: 
          item.Status = bcolors.RED + "Away" + bcolors.ENDC
          msg = bcolors.RED + "Your status is now Away" + bcolors.ENDC + newline
          item.socket.send(msg.encode('ascii'))

   

## silence a user for a certain strnick
#def silence_user_for_user(client_socket, stripmsg, user):
#  global clients
#  global chatuser_Array
#  global chat_user
#  wordCount = len(stripmsg.split())
#
#  if wordCount < 2:
#      #print(bcolors.WARNING +"Debug: less than 2 wordcount in /DM" + bcolors.ENDC)
#      totmsg = totmsg + 1
#      errormsg=bcolors.YELLOW + "You did not provide a nickname.  Retry. " +  bcolors.ENDC  + newline
#      client_socket.send(errormsg.encode('ascii'))
#  else:
#      #print(bcolors.WARNING +"Debug: 2 or more words found in /silence" + bcolors.ENDC)
#      nick  = stripmsg.split()[1]
#      strnick = str(nick)
#      #print(bcolors.WARNING +"Debug: target of DM: " + strnick + newline)
#      # finds client_socket from name
#
#  for item in chat_userArray:
#       if item.socket != client_socket: # dont' block yourself
#          item.blockedUsers.append(strnick)
#
#          for blocking_user in chat_userArray:
#               if blocking_user.socket == client_socket:
#                  print (bcolors.YELLOW + user + " has silenced user: " + strnick + bcolors.ENDC)
#                  confirmmsg=bcolors.CYAN + "You have silenced user: " + strnick  +  bcolors.ENDC  + newline
#                  client_socket.send(confirmmsg.encode('ascii'))
#       else:
#          errormsg=bcolors.YELLOW + "User: " + strnick + " not found! Try again"  +  bcolors.ENDC  + newline
#          client_socket.send(errormsg.encode('ascii'))
#
##$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

# udpate user last seen
def update_user_lastSeen(client_socket):
  global chat_user
  global chatuser_Array
  for item in chat_userArray:
      if item.socket == client_socket:
         item.lastSeen = datetime.datetime.now()

# udpate user details
def update_user_nick(client_socket, strnick):
  global clients
  global chat_user
  global chat_userArray

  for item in chat_userArray:
      if item.socket == client_socket:
         oldnick = item.nick
         item.nick = strnick
         item.lastSeen = datetime.datetime.now()



# delete user from all data strutures
def del_user(client_socket):
  global currentusers
  global maxusers
  global clients
  global chat_user
  global chat_userArray

  del clients[client_socket]
  for item in chat_userArray:
      if item.socket == client_socket:
         print(bcolors.RED + "Removed user: " + str(item.nick) + bcolors.ENDC )
         chat_userArray.remove(item)


#   # for now also add to chat_user array of structures
#   chat_userRec = chat_user(socket = client_socket, nick = full_name, \
#   logintime = datetime.datetime.now(), msgsSent = 0, msgsReceived = 0, Status = "Online")
#   chat_userArray.append(chat_userRec)
##for item in houseArray:
##    if item.city == 'Beijing':
##        print(item)


def greet_user(client_socket):
   global Version
   global Motd # message of the day
   global currentusers
   global maxusers
   global startchatmsg

   # count users into global variable
   for toBroadcast, data in clients.items():
       currentusers= currentusers + 1
       if maxusers < currentusers:
          maxusers = maxusers +1

   whosent = client_socket
   user = clients[client_socket]["name"]
   formatmsg =  strhereis + bcolors.GREEN  +str(user) + bcolors.CYAN +  str("! ") +  bcolors.ENDC + newline
   boilerplate = bcolors.CYAN + "\n\nMoshix Chat System - Version " + str(Version) + bcolors.BLUE + str(" -- /help for comands ") + bcolors.ENDC +  newline
   usergreet = bcolors.CYAN + "Welcome in, " + str(user) + bcolors.ENDC +  newline
   usergreetCount = bcolors.CYAN + "Currently there are: " + str(currentusers) + " users in this chat. Including you, of course. " + bcolors.ENDC +  newline

   for toBroadcast, data in clients.items():
       if toBroadcast != whosent:
          # inform all other users who about new arrival
          toBroadcast.send(formatmsg.encode('ascii'))
       else:
       # greet user who just signed in
           whosent.send(boilerplate.encode('ascii'))
           whosent.send(usergreet.encode('ascii'))
           whosent.send(usergreetCount.encode('ascii'))
           whosent.send(Motd.encode('ascii'))
           whosent.send(startchatmsg.encode('ascii'))



# create random name for connection
def name_client(client_socket):
   global strhereis
   global chat_userArray
   global chat_user

   first_names = ['Jordan', 'Bill', 'Sarah', 'Ruth', 'Cindy', 'Anne','Raj', 'Ron', 'Chris','Sal','David','Jacob','Oren', 'Tom', 'Greg','Doug','Josh', 'Rob', 'Sigfried', 'Hilge', 'Ralph','Alice', 'Bob', 'Charlie', 'Diana', 'Emma', 'John', 'Dennis', 'Jay']
   last_names = ['Depardieu', 'McLaughlin','Rivera','Zoff','Rossi','Danio','Mesrine','Hajin', 'Yamamoto', 'Ostrovsky','Johnson', 'Beermo', 'German', 'McCallan', 'Muller', 'Chang','Santis', 'Cohen', 'Levi', 'Hernandez','Brown', 'Green', 'White', 'Black', 'Gray', 'Baer', 'Smith', 'Holland']
   full_name = random.choice(first_names) + "_" + random.choice(last_names)
   informmsg = ['As the prophesy foretold, here is ',
                'A random apparition of ',
                'And out of the blue here comes ',
                'Behold! Here comes ',
                'No way! Look who just walked in! Its ',
                'Everybody listen up! Her Roal Highness has shown up: ',
                'Yo, yo yo! A new chatter has appeared: ',
                'The bus arrived and it brought: ',
                'Yeah! And in comes ']
   hereis = random.choice(informmsg)
   strhereis = bcolors.CYAN + str(hereis)
   print (bcolors.CYAN + "New user connected: " + full_name + " " + bcolors.ENDC)
   clients[client_socket]["name"] = full_name

   # for now also add to chat_user array of structures
   chat_userRec = chat_user(socket = client_socket, nick = full_name, \
   logintime = datetime.datetime.now(), msgsSent = 0, msgsReceived = 0, \
   lastSeen = datetime.datetime.now(), Status = "Online")
   chat_userArray.append(chat_userRec)
   #print("Debug: " + str(chat_userRec))



# Set up function to accept clients and start threaded handler
def accept_clients():
    while True:
        client_socket, address = server_socket.accept()
        clients[client_socket] = dict()
        #print(f"Connection from {address} established.")
        #server_socket.settimeout(10.0)
        name_client(client_socket)
        greet_user(client_socket)
        client_thread = threading.Thread(target=handle_client, args=(client_socket,))
        client_thread.start()


if __name__=='__main__':

   @dataclass
   class chat_user:
      socket: int
      nick: str
      logintime: datetime
      msgsSent: int
      msgsReceived: int
      lastSeen: datetime
      Status: str


   chat_userArray = [] # this is an array of all chat_user

   class bcolors:
      HEADER = '\033[95m'
      WHITE = '\033[95m'
      OKBLUE = '\033[94m'
      BLUE = '\033[94m'
      OKCYAN = '\033[96m'
      CYAN = '\033[96m'
      OKGREEN = '\033[92m'
      GREEN = '\033[92m'
      WARNING = '\033[93m'
      YELLOW = '\033[93m'
      FAIL = '\033[91m'
      RED = '\033[91m'
      ENDC = '\033[0m'
      UNDERLINE = '\033[4m'

   # default values
   HOST = "localhost"
   PORT = 8000
   if len(sys.argv) == 3:
      HOST=sys.argv[1]
      PORT = sys.argv[2]
      print(bcolors.GREEN + "You povided HOST: " + str(HOST))
      print("You provide PORT: " + str(PORT) + bcolors.ENDC)
   else:
      print (bcolors.WARNING + 'You did not provide IP and HOST as arguments \nRun this chat server with ./command 127.0.0.1 8000  [where 127.0.01 is IP and 8000 is port]\n')
      print(bcolors.BLUE + "Default value for this run of  HOST: " + str(HOST))
      print(bcolors.BLUE + "Default value for this run of  PORT: " + str(PORT) + bcolors.ENDC)
      print(bcolors.BLUE + "Moshix Chat Server version: " + str(Version) + bcolors.ENDC)

   # some default values here:

   newline = "\n\r" # also carriage return for windows compatibility
   totmsg = 0
   maxusers = 0
   currentusers = 0
   started = datetime.datetime.now()
   strhereis = " "
   helpmsg = bcolors.CYAN + "Available Commands\n\r==================\n\r/who for list of users\n\r/nick SoandSo to change your nick to SoandSo\n\r/version for version info\n\r/help for help\n\r/motd for message of the day\n\r/dm user to send a Direct Message to a user\n\r/silence user to turn off msgs from user\n\r/logoff to log off the chat server\n\r\n\r"  + bcolors.ENDC
   Motd=bcolors.FAIL + "***NEW !!***\n\rYou can now change your nick name with /nick Sigfrid\n\r" + bcolors.ENDC
   startchatmsg=bcolors.BLUE + "Start chatting now\n\r\n\r" + bcolors.ENDC

   # Set up list to store client sockets and dictionary with random names
   clients = dict()

   # Set up socket connection
   # Create socket object and bind to host and port
   server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
   server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
   intPORT = int(PORT)
   server_socket.bind((HOST, intPORT))

   # Start accepting clients
   server_socket.listen()
   print(bcolors.GREEN + "Started Moshix Chat Server with HOST and IP: "+  str(HOST) + ":" + str(PORT) +bcolors.ENDC)
   accept_thread = threading.Thread(target=accept_clients)
   accept_thread.start()

