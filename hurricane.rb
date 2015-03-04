#!/usr/bin/env ruby

=begin
Early exploration into group messaging
=end

require 'thread'
require 'socket'
require 'digest/sha2' # Defaults to size '256', supports any sized key

Thread.abort_on_exception = true # Background threads will *not* die silently

Broadcastport = 33333
Broadcastaddr = ['192.168.0.255', Broadcastport]
Broadcastsizecap = 1024 # Maximum size of broadcast datagram we'll accept

$screenlock = Mutex.new

def announce()
	localhostname = Socket.gethostname() # Get current node name
	digest = Digest::SHA2.new << localhostname
	announce = "Announce " + localhostname + " => " + digest.to_s()

	broadcast = UDPSocket.new
	broadcast.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
	broadcast.send(announce, 0, Broadcastaddr[0], Broadcastaddr[1])
	broadcast.close
end

def displayMessage(msg)
	$screenlock.synchronize {
		puts msg
	}
end

def receiveBroadcasts()
	bindaddr = ['0.0.0.0', Broadcastport]
	BasicSocket.do_not_reverse_lookup = true
	broadcast = UDPSocket.new
	broadcast.bind(bindaddr[0], bindaddr[1])
	loop {
		data, addr = broadcast.recvfrom(Broadcastsizecap)
		Thread.start do
			displayMessage(addr.to_s + ": " + data.to_s)
		end
	}
end

if __FILE__ == $0
	Thread.start() do receiveBroadcasts() end
	sleep 2
	announce()
end
