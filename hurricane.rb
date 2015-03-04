#!/usr/bin/env ruby

=begin
A simple take on torrenting.
It splits files into 10K chunks, checksums each one, and can offer or request
chunks by checksum over the network.
=end

require 'thread'
require 'socket'
require 'digest/sha2' # Defaults to size '256', supports any sized key

#
# Global constants
#
Broadcastport = 33333
Broadcastaddr = ['192.168.0.255', Broadcastport]
Broadcastsizecap = 1024 # Maximum size of broadcast datagram we'll accept
Chunksize = 10_000 # Chunk size for all files is 10K

#
# Other global state variables
#
Thread.abort_on_exception = true # Background threads will *not* die silently
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

def checksumChunk(chunk)
	digest = Digest::SHA2.new << chunk
	return digest.to_s
end

def genChecksum(dataFilename, stormFilename)
	if( ! File.file?(dataFilename) )
		puts "Error: Data file " + dataFilename + " does not exist!"
		exit 1
	end
	if( File.file?(stormFilename) )
		puts "Error: Storm file " + stormFilename + " already exists!"
		exit 1
	end
	dataFile = File.open(dataFilename, "r")
	stormFile = File.open(stormFilename, "w")
	until dataFile.eof?
		buffer = dataFile.read(Chunksize)
		stormFile.puts checksumChunk(buffer)
	end
	dataFile.close()
	stormFile.close()
end

def usage()
	puts ("USAGE: " + $0 + " <checksum|seed|download> <datafile> <stormfile>")
end

if __FILE__ == $0
	if( ARGV.length != 3 )
		usage()
		exit()
	end
	command = ARGV[0]
	dataFilename = ARGV[1]
	stormFilename = ARGV[2]
	case command
		when "checksum"
			genChecksum(dataFilename, stormFilename)
			#thr = Thread.new() { receiveBroadcasts() }
			#sleep 2
			#announce()
			#thr.join # Pause forever
		when "seed"
			puts "Seeding not yet implemented"
		when "download"
			puts "downloading not yet implemeneted"
		else
			usage()
	end
end
