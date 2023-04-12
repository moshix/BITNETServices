#!/opt/homebrew/bin/python3.10
# copyright 2023 by moshix

import socket

# Define constants
HOST = 'localhost'
PORT = 8000
BUFFER_SIZE = 1024

# Create a dictionary to store nicknames and their corresponding sockets
nicknames = {}

# Create a socket object
server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

# Bind the socket to a specific address and port
server_socket.bind((HOST, PORT))

# Listen for incoming connections
server_socket.listen()

# Function to broadcast a message to all connected clients
def broadcast(message, sender_socket):
    for socket in nicknames:
        if socket != sender_socket:
            socket.send(message)

# Function to handle client connections
def handle_client(client_socket, nickname):
    nicknames[client_socket] = nickname
    print(f'{nickname} has connected.')
    broadcast(f'{nickname} has joined the chat.', client_socket)

    while True:
        try:
            message = client_socket.recv(BUFFER_SIZE)
            if message:
                # Check for commands
                if message.startswith('/nick'):
                    new_nickname = message.split()[1]
                    nicknames[client_socket] = new_nickname
                    client_socket.send(f'Your nickname has been changed to {new_nickname}'.encode())
                elif message.startswith('/silence'):
                    user_to_silence = message.split()[1]
                    for socket, nickname in nicknames.items():
                        if nickname == user_to_silence:
                            socket.send('You have been silenced.'.encode())
                elif message.startswith('/dm'):
                    recipient = message.split()[1]
                    message_body = ' '.join(message.split()[2:])
                    for socket, nickname in nicknames.items():
                        if nickname == recipient:
                            socket.send(f'(DM from {nicknames[client_socket]}): {message_body}'.encode())
                elif message.startswith('/logoff'):
                    client_socket.send('Goodbye!'.encode())
                    client_socket.close()
                    del nicknames[client_socket]
                    broadcast(f'{nickname} has left the chat.', client_socket)
                    break
                else:
                    broadcast(f'{nickname}: {message}', client_socket)
            else:
                client_socket.close()
                del nicknames[client_socket]
                broadcast(f'{nickname} has left the chat.', client_socket)
                break
        except:
            client_socket.close()
            del nicknames[client_socket]
            broadcast(f'{nickname} has left the chat.', client_socket)
            break

# Main loop to accept incoming connections
while True:
    client_socket, address = server_socket.accept()
    print(f'Connection from {address} has been established.')
    client_socket.send('Welcome to the chat! Please enter your nickname: '.encode())
    nickname = client_socket.recv(BUFFER_SIZE).decode()
    handle_client(client_socket, nickname)

