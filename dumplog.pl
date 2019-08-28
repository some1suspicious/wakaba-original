#!/usr/bin/perl

use strict;

use Digest::MD5 qw(md5 md5_hex md5_base64);
use MIME::Base64;

use lib '.';
BEGIN { require 'config.pl'; }

dump_log();



sub dump_log()
{
	my %posts;

	foreach(read_array("log.txt"))
	{
		my @data=split /\s*,\s*/;

		my $ip=decode_ip($data[3]);
		my $host="";

		print "Thread $data[0], post $data[1]: Posted from $host ($ip)";
		print " (old post, deleted)" if($posts{"$data[0],$data[1]"});
		print " (thread deleted)" unless(-e RES_DIR.$data[0].PAGE_EXT);
		print "\n";

		$posts{"$data[0],$data[1]"}=1;
	}
}


sub read_array($)
{
	my ($filename)=@_;
	my @array;

	if(open FILE,$filename)
	{
		@array=<FILE>;
		chomp @array;
		close FILE;
	}
	return @array;
}

sub decode_ip($)
{
	my ($str)=@_;
	my ($iv,$cipher)=$str=~/^(.*)!(.*)$/;

	return rc4(decode_base64($cipher),md5(SECRET.$iv));
}

sub rc4($$)
{
	my ($message,$key)=@_;

    my @k=unpack 'C*',$key;
    my @s=0..255;
    my $y=0;
    for my $x (0..255)
    {
		$y=($k[$x%@k]+$s[$x]+$y)%256;
		@s[$x,$y]=@s[$y,$x];
    }

	my $x,$y;

	my @message=unpack 'C*',$message;
	for(@message)
	{
		$x=($x+1)%256;
		$y=($y+$s[$x])%256;
		@s[$x,$y]=@s[$y,$x];
		$_^=$s[($s[$x]+$s[$y])%256];
	}
	return pack 'C*',@message;
}
