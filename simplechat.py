#!/opt/homebrew/bin/python3.9                                                                                                          
import socket
import threading

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
        formatmsg = str("> ") + message

        # Broadcast message to all clients
        for c in clients:
            if c != whosent:
               c.send(formatmsg.encode())

# Set up function to accept clients and start threaded handler
def accept_clients():
    while True:
        client_socket, address = server_socket.accept()
        clients.append(client_socket)
        print(f"Connection from {address} established.")
        client_thread = threading.Thread(target=handle_client, args=(client_socket,))
        client_thread.start()

# Set up list to store client sockets
clients = []

# Start accepting clients
server_socket.listen()
print("Started Chat Server...")
accept_thread = threading.Thread(target=accept_clients)
accept_thread.start()
