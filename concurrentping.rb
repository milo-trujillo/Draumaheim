#!/usr/bin/env ruby

=begin
This is a simple script for testing network connectivity
that attempts to ping every node in the cluster and reports on
success or failure. It's mostly an excuse to test concurrency
and networking in Ruby.
=end

require 'socket'
require 'timeout'
require 'thread'

Nodesubnet = "192.168.0."
Nodestart = 201
Nodeend = 207

def pingecho(host, timeout=5, service="echo")
	begin
		timeout(timeout) do
		s = TCPSocket.new(host, service)
		s.close
	end
	rescue Errno::ECONNREFUSED
		return true
	rescue Timeout::Error, StandardError
		return false
	end
	return true
end

# Populate hash table with every node's IP address
nodelist = Hash.new
nodelock = Mutex.new
completedpings = 0
for x in (Nodestart .. Nodeend)
	nodelist[(Nodesubnet + x.to_s)] = false
end

# Now ping all of them
nodelist.keys.each do |node|
	puts "Pinging #{node}..."
	Thread.start(node) do |host|
		success = pingecho(node.to_s)
		if success
			nodelock.synchronize {
				nodelist[host] = true
				completedpings += 1
			}
		else
			nodelock.synchronize {
				completedpings += 1
			}
		end
	end
end

loop {
	# This does *not* need to be mutex locked, because if 6 is being changed to
	# seven while we're reading it then who cares? We're just going to check it
	# again in a second
	if( completedpings == nodelist.size )
		nodelist.keys.each do |node|
			if( nodelist[node] == true )
				puts (node + " is online")
			else
				puts (node + " is offline")
			end
		end
		exit
	end	
}

