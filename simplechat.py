#!/opt/homebrew/bin/python3.10
#!/usr/local/bin/python3.10
#!/opt/homebrew/bin/python3.9
import socket
import threading
import random
import signal
import sys
import string
import time
import datetime


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
# v 1.9  TODO Re-organize into more functions (for send, for search of users etc)
# v 2.0  TODO SSL comms


Version = "1.6"

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

#print ('Number of arguments:', len(sys.argv), 'arguments.')
#print ('Argument List:', str(sys.argv))
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


newline = "\n"
totmsg = 0
maxusers = 0
currentusers = 0
started = datetime.datetime.now()
strhereis = " "
helpmsg = bcolors.CYAN + "Available Commands\n==================\n/who for list of users\n/nick SoandSo to change your nick to SoandSo\n/version for version info\n/help for help\n/motd for message of the day\n/dm user to send a Direct Message to a user\n/logoff to log off the chat server\n\n"  + bcolors.ENDC
Motd=bcolors.FAIL + "***NEW !!***\nYou can now change your nick name with /nick Sigfrid\n" + bcolors.ENDC
startchatmsg=bcolors.BLUE + "Start chatting now\n\n" + bcolors.ENDC 


# Set up socket connection
# Create socket object and bind to host and port
server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
intPORT = int(PORT)
server_socket.bind((HOST, intPORT))


# Set up list to store client sockets and dictionary with random names
clients = dict()


# Set up function to handle client messages
def handle_client(client_socket):
    try:
        while True:
            # Receive message from client

            global totmsg
            global maxusers
            global currentusers
            global started
            global helpmsg
            global Motd
            nickExists = "False"  # for dupblicate nickname checking 

            # some stats keeping
            currentusers = 0
            for toBroadcast, data in clients.items():
                 currentusers= currentusers + 1
                 if maxusers < currentusers:
                     maxusers = maxusers +1

            whosent = 0
            received = client_socket.recv(1024)
            if(received == b''):
                print("client disconnected")
                client_socket.close()
                break
            message = received.decode()
            stripmsg=message.strip() #strip of newline
            whosent = client_socket
            user = clients[client_socket]["name"]

            if stripmsg != "":
               print("user: ",user, " wrote: ", message) # for console
            formatmsg = user + "> " + message
            #print ("Debug: msg: " + stripmsg + newline)
 
            # handle  help request
            if stripmsg[:5] == "/Help" or stripmsg[:5] == "/help":
                totmsg = totmsg + 1
                whosent.send(helpmsg.encode())
                continue
 
           # handle message of the dasy (motd) request
            if stripmsg[:4] == "/Mot" or stripmsg[:4] == "/mot":
                totmsg = totmsg + 1
                whosent.send(Motd.encode())
                continue

            # handle version request
            if stripmsg[:4] == "/Vers" or stripmsg[:4] == "/ver":
                totmsg = totmsg + 1
                versionmsg = str(bcolors.CYAN + "Moshix Chat Server is currently running Version: ") + str(Version) + bcolors.ENDC + newline
                whosent.send(versionmsg.encode())
                continue

            # handle stats request
            if stripmsg[:6] == "/stats" or stripmsg[:5] == "/Stats":
                totmsg = totmsg + 1
                strtotmsg = str(totmsg)
                strcurrentusers = str(currentusers)
                strmaxusers = str(maxusers)
                strstarted = str(started)
                statsmsg = str(bcolors.CYAN +"Chat server up since: " + strstarted[:19] + " - total messages sent: " + strtotmsg + " - current users: " + strcurrentusers + " - Max users seen: " + strmaxusers + bcolors.ENDC + newline)
                whosent.send(statsmsg.encode())
                continue


            # handle to change nick name with /nick
            if stripmsg[:5] == "/nick" or stripmsg[:5] == "/Nick":
                #print ("Debug: Entered /nick function ")
                wordCount = len(stripmsg.split())
                #print ("Debug: /nick number of words: ", wordCount)

                if wordCount < 2:
                    totmsg = totmsg + 1
                    errormsg=bcolors.YELLOW  + "You need to provide a one word nickname, like:  /nick JiffyLube. Retry. " +  bcolors.ENDC  + newline
                    whosent.send(errormsg.encode())
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
                        clients[client_socket]["name"] = strnick
                        print(bcolors.CYAN + "User: " + str(user) + " has changed name to: " +strnick + bcolors.ENDC) #also print on console
                        confirm = bcolors.CYAN + "Your nick has been changed to: " + bcolors.WHITE + strnick +  bcolors.ENDC + newline
                        totmsg = totmsg + 1
                        whosent.send(confirm.encode())

                        # now inform all users of name change
                        for toBroadcast, data in clients.items():
                            if toBroadcast != whosent:
                               totmsg = totmsg + 1
                               nickchangemsg = bcolors.CYAN + "User: " + str(user) + " has changed nickname to: " + bcolors.GREEN + strnick + bcolors.ENDC + newline
                               toBroadcast.send(nickchangemsg.encode())
                    else: 
                        confirm = bcolors.WARNING + "No can  do. This nickname already exists... " + bcolors.WHITE + strnick +  bcolors.ENDC + newline
                        totmsg = totmsg + 1
                        whosent.send(confirm.encode())

                continue

            # handle send direct message to a particular user
            if stripmsg[:3] == "/dm" or stripmsg[:3] == "/Dm":
                wordCount = len(stripmsg.split())

                if wordCount < 2:
                    print(bcolors.WARNING +"Debug: less than 2 wordcount in /DM" + bcolors.ENDC)
                    totmsg = totmsg + 1
                    errormsg=bcolors.YELLOW + "You did not provide a nickname.  Retry. " +  bcolors.ENDC  + newline
                    whosent.send(errormsg.encode())
                    continue
                if wordCount < 3:
                    #print(bcolors.WARNING +"Debug: less than 3 wordcount in /DM" + bcolors.ENDC)
                    totmsg = totmsg + 1
                    errormsg= bcolors.YELLOW + "You did not provide a DM.  Retry. " +  bcolors.ENDC  + newline
                    whosent.send(errormsg.encode())
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
                        whosent.send(confirm.encode())
                        DMmsg=bcolors.GREEN +  "DM from " + str(user) + " > " + strdm + bcolors.ENDC + newline
                        toDm.send(DMmsg.encode())
                    else:
                        totmsg = totmsg + 1
                        confirm = bcolors.YELLOW + "Your DM cannot be sent. Nick not existing or logged out meanwhile. " +  bcolors.ENDC  + newline
                        whosent.send(confirm.encode())
                continue


            # send list of logged in users to requesting client
            if stripmsg[:6] == "/users/" or stripmsg[:4] == "/who" or stripmsg[:4] == "/Who":
                counter = 0
                for toBroadcast, data in clients.items():
                    totmsg = totmsg + 1
                    counter = + counter + 1
                    strcounter = str(counter)
                    listuser = clients[toBroadcast]["name"]
                    detail = str(bcolors.CYAN + strcounter + " - " + listuser + bcolors.ENDC  + newline)
                    whosent.send(detail.encode())
                continue


            if stripmsg[:7] == "/logoff" or strimpmsg[:7] == "/LOGOFF":
              if client_socket in clients:
                 logoffmsg= bcolors.YELLOW + "Ok, then. See you soon! " +  bcolors.ENDC  + newline
                 totmsg = totmsg + 1
                 whosent.send(logoffmsg.encode())
                 whosent.close()
                 del clients[client_socket]
                 # now inform all users of name change
                 for toBroadcast, data in clients.items():
                     if toBroadcast != whosent:
                        totmsg = totmsg + 1
                        usergonemsg = bcolors.CYAN + "User: " + str(user) + " has left. " + bcolors.GREEN + strnick + bcolors.ENDC + newline
                        toBroadcast.send(usergonemsg.encode())
              continue

            # Broadcast message to all clients
            if stripmsg != "":
              for toBroadcast, data in clients.items():
                  if toBroadcast != whosent:
                      totmsg = totmsg + 1
                      toBroadcast.send(formatmsg.encode())
                  #else:
                  #    whosent.send(receipt.encode())
           #except socket.timeout: 
           #  if client_socket in clients:
           #     del clients[client_socket]

    except (ConnectionResetError, OSError):
        print("Client connetion reset")
    finally:
        if client_socket in clients:
            del clients[client_socket]
# end of handle_cient function 

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
          toBroadcast.send(formatmsg.encode())
       else:
       # greet user who just signed in
           whosent.send(boilerplate.encode())
           whosent.send(usergreet.encode())
           whosent.send(usergreetCount.encode())
           whosent.send(Motd.encode())
           whosent.send(startchatmsg.encode())



# create random name for connection
def name_client(client_socket):
   global strhereis

   first_names = ['Raj', 'Ron', 'Chris','Sal','David','Jacob','Oren', 'Tom', 'Greg','Doug','Josh', 'Rob', 'Sigfried', 'Hilge', 'Ralph','Alice', 'Bob', 'Charlie', 'Diana', 'Emma', 'John', 'Dennis', 'Jay']
   last_names = ['Depardieu', 'McLaughlin','Rivera','Zoff','Rossi','Danio','Mesrine','Hajin', 'Yamamoto', 'Ostrovsky','Johnson', 'Beermo', 'Santis', 'Cohen', 'Levi', 'Hernandez','Brown', 'Green', 'White', 'Black', 'Gray', 'Baer', 'Smith', 'Holland']
   full_name = random.choice(first_names) + "_" + random.choice(last_names)
   informmsg = ['As the prophesy foretold, here is ',
                'A random apparition of ',
                'And out of the blue here comes ',
                'Behold! Here comes ',
                'No way! Look who just walked in! Its ',
                'Everybody listen up! Her Roal Highness has shown up: ',
                'Yo, yo yo! A new chatter has appeared: ',
                'Yeah! And in comes ']
   hereis = random.choice(informmsg)            
   strhereis = bcolors.CYAN + str(hereis)
   # debug only: print ("name_client func   - full_name: ", full_name, "client_socket", client_socket)
   clients[client_socket]["name"] = full_name


# Set up function to accept clients and start threaded handler
def accept_clients():
    while True:
        client_socket, address = server_socket.accept()
        clients[client_socket] = dict()
        print(f"Connection from {address} established.")
        #server_socket.settimeout(10.0)
        name_client(client_socket)
        greet_user(client_socket)
        client_thread = threading.Thread(target=handle_client, args=(client_socket,))
        client_thread.start()


# Start accepting clients
server_socket.listen()
print(bcolors.GREEN + "Started Moshix Chat Server with HOST and IP: "+  str(HOST) + ":" + str(PORT) +bcolors.ENDC)
accept_thread = threading.Thread(target=accept_clients)
accept_thread.start()

