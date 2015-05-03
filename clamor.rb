#!/usr/bin/env ruby

=begin
An extremely simple IRC bot, serves mostly as an example to draw from later.
=end

require "cinch"
require "socket"
  
class Greeter
	include Cinch::Plugin # Inherit from generic irc bot
  
	match /hello$/, method: :greet # Call greet if !hello encountered
	def greet(m)
		m.reply "Hi there, my name is " + Socket.gethostname
	end
end
 
def usage()
	puts "USAGE: clamor <irc-server-address>" 
end
 
if __FILE__ == $0
	if( ARGV.length != 1 )
		usage()
		exit()
	end
	hostname = Socket.gethostname
	bot = Cinch::Bot.new do
		configure do |c|
			c.nick = hostname
			c.server = ARGV[0]
			c.channels = ["#clamor-test"]
			c.plugins.plugins = [Greeter]
		end
	end
	bot.start
end
