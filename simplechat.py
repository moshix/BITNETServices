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
# v 0.1 humble beginnings
# v 0.2 Added random names
# v 0.3 Greet user individually
# v 0.4 Inform other users that a certain users has disconnected, then delete from names{}
# v 0.5 Handle command /who
# v 0.6 Handle /stats
# v 0.7 Handle /help

# dictionary how-to: https://www.guru99.com/python-dictionary-append.html
# Set up socket connection
HOST = "localhost"
PORT = 8000
totmsg = 0
maxusers = 0
currentusers = 0
Version = "0.7"
started = datetime.datetime.now()

# Create socket object and bind to host and port
server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server_socket.bind((HOST, PORT))


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
            receipt = "< \n"
            helpmsg = "/who for list of users"

            # handle  help request 
            if stripmsg== "Help" or stripmsg== "/help":
                totmsg = totmsg + 1
                whosent.send(helpmsg.encode())

            # handle version request
            if stripmsg== "/Ver"[:4] or stripmsg== "/ver"[:4]:
                totmsg = totmsg + 1
                versionmsg = str("Moshix Chat Server is currently running Version: ") + str(Version) + "\n"  
                whosent.send(Version.encode())
            
            # handle stats request
            if stripmsg== "/stats"[:6] or stripmsg== "/Stats"[:6]:
                totmsg = totmsg + 1
                strtotmsg = str(totmsg)
                strcurrentusers = str(currentusers)
                strmaxusers = str(maxusers)
                strstarted = str(started)
                statsmsg = str("Chat server up since: " + strstarted[:19] + " - total messages sent: " + strtotmsg + " - current users: " + strcurrentusers + " - Max users seen: " + strmaxusers + "\n")
                whosent.send(statsmsg.encode())

            # send list of logged in users to requesting client
            if stripmsg == "/who"[:4] or stripmsg == "/Who":
                counter = 0
                for toBroadcast, data in clients.items():
                    counter = + counter + 1
                    strcounter = str(counter)
                    listuser = clients[toBroadcast]["name"]
                    detail = str(strcounter + " - " + listuser + " \n")
                    whosent.send(detail.encode())

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



# create random name for connection
def name_client(client_socket):

   first_names = ['Raj', 'Oren', 'Ben', 'Eden', 'Greg','Josh', 'Rob', 'Sigfried', 'Hilge', 'Ralph','Alice', 'Bob', 'Charlie', 'Diana', 'Emma', 'John', 'Dennis', 'Jay']
   last_names = ['Depardieu', 'Hajij', 'Yamamoto', 'Ostrovsky','Sundlof', 'Hauser', 'Wagner', 'Cohen', 'Levi', 'Hernandez','Brown', 'Green', 'White', 'Black', 'Gray', 'Baer', 'Smith', 'Holland']
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
print("Started Moshix Chat Server...")
accept_thread = threading.Thread(target=accept_clients)
accept_thread.start()

