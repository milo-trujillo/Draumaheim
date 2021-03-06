#!/usr/bin/env ruby

=begin
A simple take on torrenting.
It splits files into 50K chunks, checksums each one, and can offer or request
chunks by checksum over the network.
=end

require 'thread'
require 'timeout'
require 'socket'
require 'digest/sha2' # Defaults to size '256', supports any sized key

#
# Global constants
#
Broadcastport = 33333
Broadcastaddr = ['192.168.0.255', Broadcastport]
Broadcastsizecap = 1024 # Maximum size of broadcast datagram we'll accept
Chunksize = 50_000 # Chunk size for all files is 50K
Announcetimeout = 10 # Ten seconds of no response before we drop it

# These are for tracking the status of individual file chunks
Incomplete = 0
Processing = 1
Completed  = 2

# How long to pause before repeating announcements to the network
Announcewait = 30

#
# Other global state variables
#
Thread.abort_on_exception = true # Background threads will *not* die silently
$screenlock = Mutex.new   # Lock for printing to screen
$hashlock = Mutex.new     # Lock for accessing checksum / status lists
$filelock = Mutex.new     # Lock for writing to datafile
$announcelock = Mutex.new # Lock for accessing broadcast list

def announce(msg)
	broadcast = UDPSocket.new
	broadcast.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
	broadcast.send(msg.to_s, 0, Broadcastaddr[0], Broadcastaddr[1])
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

# This requests each chunk from other nodes and downloads if they respond
def requestChunk(number, checksums, statuses)
	checksum = ""
	$hashlock.synchronize {
		# First we need to lock this chunk so noone else tries to grab it
		statuses[number] = Processing
		checksum = checksums[number]
	}
	announce("REQUEST " + checksum)
	# Now until we time-out, see if anyone responds with the chunk
	begin
		timeout(Announcetimeout) do
		loop {
			sleep 2
			$announcelock.synchronize {
				# Read responses we've gotten, see if relevant
			}
			#displayMessage("Downloading chunk #" + number.to_s)
		}
	end
	rescue Timeout::Error
		$hashlock.synchronize {
			statuses[number] = Incomplete
		}
	end
end

# Here we basically read in all of the checksums we'll be interested in
# and then while we're not done downloading we kick off a thread to get each chunk
def beginDownload(dataFilename, stormFilename)
	checksums = Array.new
	statuses  = Array.new
	if( File.file?(dataFilename) )
		puts "Error: Data file " + dataFilename + " already exists!"
		exit 1
	end
	if( ! File.file?(stormFilename) )
		puts "Error: Storm file " + stormFilename + " does not exist!"
		exit 1
	end
	dataFile = File.open(dataFilename, "w")
	stormFile = File.open(stormFilename, "r")
	until stormFile.eof?
		checksum = stormFile.readline.chomp
		checksums.push(checksum)
		statuses.push(Incomplete)
	end
	done = false
	while( ! done )
		$hashlock.synchronize {
			done = true
			for number in 0 .. (checksums.size - 1) do
				if( statuses[number] == Incomplete )
					done = false
					Thread.new() { requestChunk(number, checksums, statuses) }
					sleep 0.2 
					# If we don't sleep then "number" is changed before the
					# thread can be created. Real obnoxious bug.
				end				
			end
		}
		sleep Announcewait
	end
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
		when "seed"
			puts "Seeding not yet implemented"
		when "download"
			beginDownload(dataFilename, stormFilename)
		else
			usage()
	end
	#thr = Thread.new() { receiveBroadcasts() }
	#sleep 2
	#announce()
	#thr.join # Pause forever
end
