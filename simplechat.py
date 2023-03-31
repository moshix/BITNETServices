#!/opt/homebrew/bin/python3.9
import socket
import threading
import random
# Copyright 2023 by moshix
# v 0.1 humble beginnings
# v 0.2 Added random names
# TODO v0.3 pass it IP and port for connection
# TODO v0.4 Inform other users that a certain users has disconnected, then delete from names{}

# dictionary how-to: https://www.guru99.com/python-dictionary-append.html
# Set up socket connection
HOST = "localhost"
PORT = 8000

# Create socket object and bind to host and port
server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server_socket.bind((HOST, PORT))

# Set up function to handle client messages
def handle_client(client_socket):
    while True:
        whosent = 0

        # Receive message from client
        message = client_socket.recv(1024).decode()
        whosent = client_socket
        user = names[client_socket]
        print("user: ",user, " wrote: ", message) # for console
        formatmsg = str(names[client_socket]) + str("> ") + message

        # Broadcast message to all clients
        for c in clients:
            if c != whosent:
               c.send(formatmsg.encode())
# create random name for connection
def name_client(client_socket):

   first_names = ['Greg','Josh', 'Rob', 'Sigfried', 'Hilge', 'Ralph','Alice', 'Bob', 'Charlie', 'Diana', 'Emma', 'Moshix', 'Dennis', 'Jay']
   last_names = ['Sundlof', 'Hauser', 'Wagner', 'Cohen', 'Levi', 'Hernandez','Brown', 'Green', 'White', 'Black', 'Gray', 'Baer', 'Smith', 'Holland']
   full_name = random.choice(first_names) + " " + random.choice(last_names)
   # debug only: print ("name_client func   - full_name: ", full_name, "client_socket", client_socket)
   names[client_socket]=full_name


# Set up function to accept clients and start threaded handler
def accept_clients():
    while True:
        client_socket, address = server_socket.accept()
        clients.append(client_socket)
        print(f"Connection from {address} established.")
        client_thread = threading.Thread(target=handle_client, args=(client_socket,))
        name_client(client_socket)
        client_thread.start()

# Set up list to store client sockets and dictionary with random names
clients = []
names = {}

# Start accepting clients
server_socket.listen()
print("Started Chat Server...")
accept_thread = threading.Thread(target=accept_clients)
accept_thread.start()
