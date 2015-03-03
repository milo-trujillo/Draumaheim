#!/usr/bin/env perl
#
# This code adapted from http://sourceforge.net/p/netcat/bugs/42/
#
# There's a known bug in GNU netcat in which it switches from broadcast to
# unicast mode after receiving one datagram. This is not acceptable for our
# testing, so we'll use a quick Perl script instead.
#

#
# UDP Listen
#
use IO::Socket::INET;
use warnings;
use strict;

my $port = 33333;

my $sock=IO::Socket::INET->new(Proto => 'udp', LocalPort => $port) or die "Can't bind: $@\n";

print scalar localtime().": Awaiting data...\n";

my $data;
while($sock->recv($data, 1024)) 
{
	my ($port, $ipaddr) = sockaddr_in($sock->peername);
	#my ($peerhost)=gethostbyaddr($ipaddr, AF_INET);
	my ($peerip) = inet_ntoa($ipaddr);
	chomp($data);

	print scalar(localtime().": Rcvd $data from $peerip\n");
}

print "Done\n";
