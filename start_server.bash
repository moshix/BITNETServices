#!/bin/bash
port=666
echo "server starting on port $port"
tcpserver -c 1 -HR -u 65534 -g 65534 0.0.0.0 $port ./bashchat
