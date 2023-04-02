#!/usr/local/bin/python3.10
import socket
import threading
import random
import signal
import sys
import string
import time
import datetime


# Copyright 2023 by moshix
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
# v 1.0  TODO DM between users

Version = "1.00"

# default values 
HOST = "localhost"
PORT = 8000

#print ('Number of arguments:', len(sys.argv), 'arguments.')
print ('Argument List:', str(sys.argv))
if len(sys.argv) == 3:
    HOST=sys.argv[1]
    PORT = sys.argv[2]
    print("You povided HOST: " + str(HOST))
    print("You provide PORT: " + str(PORT))
else:
    print ('Wrong command line arguments! \nExecute this chat server ./command 127.0.0.1 8000  [where 127.0.01 is IP and 8000 is port]\n')
newline = "\n"
totmsg = 0
maxusers = 0
currentusers = 0
started = datetime.datetime.now()
helpmsg = "Available Commands\n==================\n/who for list of users\n/nick SoandSo to change your nick to SoandSo\n/version for version info\n/help for help\n/motd for message of the day\nDM user to send a direct message to a user\n\n"
Motd="***NEW !!***\nYou can now change your nick name with /nick Sigfrid\n"
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
                versionmsg = str("Moshix Chat Server is currently running Version: ") + str(Version) + newline
                whosent.send(versionmsg.encode())
                continue
            
            # handle stats request
            if stripmsg[:6] == "/stats" or stripmsg[:5] == "/Stats":
                totmsg = totmsg + 1
                strtotmsg = str(totmsg)
                strcurrentusers = str(currentusers)
                strmaxusers = str(maxusers)
                strstarted = str(started)
                statsmsg = str("Chat server up since: " + strstarted[:19] + " - total messages sent: " + strtotmsg + " - current users: " + strcurrentusers + " - Max users seen: " + strmaxusers + "\n")
                whosent.send(statsmsg.encode())
                continue


            # handle to change nick name with /nick
            if stripmsg[:5] == "/nick" or stripmsg[:5] == "/Nick":
                #print ("Debug: Entered /nick function ")
                wordCount = len(stripmsg.split()) 
                #print ("Debug: /nick number of words: ", wordCount)
                
                if wordCount < 2:
                    totmsg = totmsg + 1
                    errormsg="You need to provide a one word nickname, like:  /nick JiffyLube. Retry. \n"
                    whosent.send(errormsg.encode())
                else:
                    nick = stripmsg.split()[1]
                    strnick = str(nick)
                    clients[client_socket]["name"] = strnick
                    confirm = "Your nick has been changed to" + strnick + "\n"
                    totmsg = totmsg + 1
                    whosent.send(confirm.encode())
                continue

            # handle send direct message to a particular user
            if stripmsg[:3] == "/dm" or stripmsg[:3] == "/Dm":      
                wordCount = len(stripmsg.split())                       
                                                                        
                if wordCount < 2:                                       
                    totmsg = totmsg + 1                                 
                    errormsg="You did not provide a nickname to whom you want to send a DM.  Retry. \n"
                    whosent.send(errormsg.encode())                     
                else:                                                   
                    dm = stripmsg.split()[1]                          
                    strnick = str(dm)                                 
                    totmsg = totmsg + 1                                 
                    confirm = "Message to sent to" + str(dm) + newline
                    whosent.send(confirm.encode())                      
                continue  


            # send list of logged in users to requesting client
            if stripmsg[:4] == "/who" or stripmsg[:4] == "/Who":
                counter = 0
                for toBroadcast, data in clients.items():
                    totmsg = totmsg + 1
                    counter = + counter + 1
                    strcounter = str(counter)
                    listuser = clients[toBroadcast]["name"]
                    detail = str(strcounter + " - " + listuser + " \n")
                    whosent.send(detail.encode())
                continue

            # Broadcast message to all clients
            if stripmsg != "":
              for toBroadcast, data in clients.items():
                  if toBroadcast != whosent:
                      totmsg = totmsg + 1
                      toBroadcast.send(formatmsg.encode())
                  #else: 
                  #    whosent.send(receipt.encode())
 

    except (ConnectionResetError, OSError):
        print("client connetion reset")
    finally:
        if client_socket in clients:
            del clients[client_socket]


def greet_user(client_socket):
   global Version
   global Motd # message of the day
   whosent = client_socket
   user = clients[client_socket]["name"]
   formatmsg = str("Look who just came in from the cold! It's  ")  +str(user) + str("! ") + str("\n")
   boilerplate = str("\n\nMoshix Chat System - Version ") + str(Version) + str("-- /help for comands ") +  str("\n")
   usergreet = str("Welcome ") + str(user) +str("!  \n")

   for toBroadcast, data in clients.items():
       if toBroadcast != whosent:
          # inform all other users who about new arrival
          toBroadcast.send(formatmsg.encode())
       else:
       # greet user who just signed in
           whosent.send(boilerplate.encode())
           whosent.send(usergreet.encode())
           whosent.send(Motd.encode())



# create random name for connection
def name_client(client_socket):

   first_names = ['Raj', 'Oren', 'Tom', 'Greg','Josh', 'Rob', 'Sigfried', 'Hilge', 'Ralph','Alice', 'Bob', 'Charlie', 'Diana', 'Emma', 'John', 'Dennis', 'Jay']
   last_names = ['Depardieu', 'Hajin', 'Yamamoto', 'Ostrovsky','Johnson', 'Beermo', 'Santis', 'Cohen', 'Levi', 'Hernandez','Brown', 'Green', 'White', 'Black', 'Gray', 'Baer', 'Smith', 'Holland']
   full_name = random.choice(first_names) + " " + random.choice(last_names)
   # debug only: print ("name_client func   - full_name: ", full_name, "client_socket", client_socket)
   clients[client_socket]["name"] = full_name


# Set up function to accept clients and start threaded handler
def accept_clients():
    while True:
        client_socket, address = server_socket.accept()
        clients[client_socket] = dict()
        print(f"Connection from {address} established.")
        name_client(client_socket)
        greet_user(client_socket)
        client_thread = threading.Thread(target=handle_client, args=(client_socket,))
        client_thread.start()


# Start accepting clients
server_socket.listen()
print("Started Moshix Chat Server with HOST and IP: ", str(HOST) + ":" + str(PORT))
accept_thread = threading.Thread(target=accept_clients)
accept_thread.start()
#!/opt/homebrew/bin/python3.10
