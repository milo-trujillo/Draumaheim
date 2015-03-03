#!/usr/bin/env ruby

require 'socket'
require 'digest/sha2' # Defaults to size '256', supports any sized key

broadcastport = 33333
broadcastaddr = ['192.168.0.255', broadcastport]

localhostname = Socket.gethostname() # Get current node name
digest = Digest::SHA2.new << localhostname
announce = "Announce " + localhostname + " => " + digest.to_s()

broadcast = UDPSocket.new
broadcast.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
broadcast.send(announce, 0, broadcastaddr[0], broadcastaddr[1])
broadcast.close

print announce + "\n"
