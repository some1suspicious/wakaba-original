#!/usr/bin/perl

use CGI::Carp qw(fatalsToBrowser);

use strict;

use lib '.';
BEGIN { require 'oekaki_config.pl'; }

my $ip=$ENV{REMOTE_ADDR};
my $tmpname=TMP_DIR.$ip.'.png';

my $metadata=<STDIN>; # not actually used - feel free to implement.

open FILE,">$tmpname" or die("Couldn't write to directory");

binmode FILE;
binmode STDIN;

my $buffer;
while(read(STDIN,$buffer,1024)) { print FILE $buffer; }

close FILE;

print "Content-Type: text/plain\n";
print "\n";
print "ok";
