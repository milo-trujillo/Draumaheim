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

Thread.abort_on_exception = true

$screenlock = Mutex.new

def forwardMessage(ttl = TTL, msg)
	for x in ( 1 .. Forwardhosts )
		Thread.start() do
			target = Nodestart + Random.rand(Nodeend - Nodestart + 1)
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
				$screenlock.synchronize {
					puts "Error reading message, received:"
					puts capture.captures
				}
				exit
			end
			ttl, msg = capture.captures
			$screenlock.synchronize {
				puts "Received message: [TTL " + ttl.to_s + "] " + msg
			}
			if( ttl.to_i > TTL || ttl.to_i == 0 )
				exit
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
