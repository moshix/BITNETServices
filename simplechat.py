#!/opt/homebrew/bin/python3.9
import socket
import threading
import random
import signal
import sys
import string



# Copyright 2023 by moshix
# v 0.1 humble beginnings
# v 0.2 Added random names
# v 0.3 Greet user individually
# v 0.4 Inform other users that a certain users has disconnected, then delete from names{}
# TODO handle simple commands like /who
# TODO  
# TODO 

# dictionary how-to: https://www.guru99.com/python-dictionary-append.html
# Set up socket connection
HOST = "localhost"
PORT = 8000

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

            # handle commands 
            if message == "Help" or message == "help":
                whosent.send(helpmsg.encode())

            # send list of logged in users to requesting client
            if message == "/who"[:4] or message == "/Who":
                for toBroadcast, data in clients.items():
                    listuser = clients[toBroadcast]["name"]
                    whosent.send(listuser,encode())

            # Broadcast message to all clients
            if stripmsg != "":
              for toBroadcast, data in clients.items():
                  if toBroadcast != whosent:
                      toBroadcast.send(formatmsg.encode())
                  #else: 
                  #    whosent.send(receipt.encode())
  
    except (ConnectionResetError, OSError):
        print("client connetion reset")
    finally:
        if client_socket in clients:
            del clients[client_socket]


def greet_user(client_socket):
   Version = "0.4"
   whosent = client_socket
   user = clients[client_socket]["name"]
   formatmsg = str("Look who just came in from the cold! It's  ")  +str(user) + str("! ") + str("\n")
   boilerplate = str("\n\nMoshix Chat System - Version ") + str(Version) + str("\n")
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

