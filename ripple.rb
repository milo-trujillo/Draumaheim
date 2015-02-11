#!/usr/bin/env ruby

require 'socket'
require 'thread'

# Global config
Nodesubnet = "192.168.0."
Nodestart = 201
Nodeend = 207
Port = 3000
Forwardhosts = 2 # Number of additional nodes to forward to
TTL = 2 # Number of hops a message can make before discarding
Pause = 1 # Number of seconds to wait before relaying a message

def forwardMessage(ttl = TTL, msg)
	puts "Forwarding msg: \"" + msg + "\" with TTL " + ttl.to_s
	for x in ( 1 .. Forwardhosts )
		Thread.start() do
			target = Nodestart + Random.rand(Nodeend - Nodestart + 1)
			puts "Forwarding to " + Nodesubnet + target.to_s
			s = TCPSocket.open(Nodesubnet + target.to_s, Port)
			s.puts(ttl.to_s + " " + msg.to_s)
			s.close
		end
	end
end

def listen()
	server = TCPServer.open(Port)
	loop {
		Thread.start(server.accept) do |client|
			line = client.gets
			client.close
			capture = /^(\d+) (.*)/.match(line)
			if( capture.size != 3 ) # First match is the entire result
				puts "Error reading message, received:"
				puts capture.captures
				return
			end
			ttl, msg = capture.captures
			puts "Received message: [TTL " + ttl.to_s + "] " + msg
			if( ttl > TTL || ttl == 0 )
				return
			end
			sleep(Pause)
			forwardMessage(ttl.to_i - 1, msg)
		end
	}	
end

if __FILE__ == $0
	Thread.start() do listen end
	loop {
		msg = gets
		forwardMessage(msg.chop)
	}
end
