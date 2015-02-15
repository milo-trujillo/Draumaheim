#!/usr/bin/env python
from arprequest import ArpRequest

class bcolors:
	HEADER = '\033[95m'
	OKBLUE = '\033[94m'
	OKGREEN = '\033[92m'
	WARNING = '\033[93m'
	FAIL = '\033[91m'
	ENDC = '\033[0m'
	BOLD = '\033[1m'
	UNDERLINE = '\033[4m'

# Try an address that exists
ar = ArpRequest('192.168.0.201', 'eth0')
print "192.168.0.201 is ",
if (ar.request()):
	print bcolors.OKGREEN + "online" + bcolors.ENDC
else:
	print bcolors.FAIL + "offline" + bcolors.ENDC

# Cool, now try one that doesn't
ar2 = ArpRequest('192.168.0.99', 'eth0')
print "192.168.0.99 is ",
if (ar2.request()):
	print bcolors.OKGREEN + "online" + bcolors.ENDC
else:
	print bcolors.FAIL + "offline" + bcolors.ENDC
