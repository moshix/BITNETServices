#!/opt/homebrew/bin/python3.10
import socket
import ssl
import select
import os
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
# v 2.4  /silence user NG
# v 2.5 now with SSL and ssh keys !

Version = "2.5"
# Load SSH keys
with open('server_key.pem', 'rb') as f:
    server_key = f.read()
with open('server_cert.pem', 'rb') as f:
    server_cert = f.read()

# Define SSL context
context = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
context.load_cert_chain(certfile='server_cert.pem', keyfile='server_key.pem')

# Define server settings
HOST = 'localhost'
PORT = 8000
BUFFER_SIZE = 1024

# Define user data structure
users = {}

# Define command functions
def change_nickname(user, nickname):
    users[user]['nickname'] = nickname

def direct_message(sender, recipient, message):
    if recipient in users:
        users[recipient]['socket'].send(f'{sender}: {message}'.encode())
    else:
        users[sender]['socket'].send(f'{recipient} is not online.'.encode())

def list_users(user):
    user_list = ', '.join(users.keys())
    users[user]['socket'].send(f'Online users: {user_list}'.encode())

def logoff(user):
    users[user]['socket'].close()
    del users[user]

# Define main function
def main():
    # Create server socket
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server_socket.bind((HOST, PORT))
    server_socket.listen()

    # Set up select loop
    inputs = [server_socket]
    outputs = []
    while inputs:
        readable, writable, exceptional = select.select(inputs, outputs, inputs)

        # Handle readable sockets
        for sock in readable:
            if sock is server_socket:
                # Accept new connection
                conn, addr = sock.accept()
                conn = context.wrap_socket(conn, server_side=True)
                inputs.append(conn)
                users[conn] = {'nickname': f'User{len(users)+1}', 'socket': conn}
                conn.send(f'Welcome to the chat server, {users[conn]["nickname"]}!'.encode())
            else:
                # Receive message from client
                data = sock.recv(BUFFER_SIZE)
                if data:
                    # Parse command and arguments
                    command, *args = data.decode().strip().split()

                    # Execute command
                    if command == 'nick':
                        change_nickname(sock, args[0])
                    elif command == 'dm':
                        direct_message(users[sock]['nickname'], args[0], ' '.join(args[1:]))
                    elif command == 'list':
                        list_users(sock)
                    elif command == 'logoff':
                        logoff(sock)
                        inputs.remove(sock)
                else:
                    # Client has disconnected
                    logoff(sock)
                    inputs.remove(sock)

        # Handle exceptional sockets
        for sock in exceptional:
            logoff(sock)
            inputs.remove(sock)

if __name__ == '__main__':
    main()
