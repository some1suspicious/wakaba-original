#!/usr/bin/perl

use CGI::Carp qw(fatalsToBrowser);

use strict;

use CGI;
use LWP;
use HTTP::Request::Common;



#
# Import settings
#

use lib '.';
BEGIN { require "config.pl"; }
BEGIN { require "config_defaults.pl"; }
BEGIN { require "strings_en.pl"; }
BEGIN { require "oekaki_style.pl"; }
BEGIN { require "oekaki_config.pl"; }
BEGIN { require "oekaki_strings_en.pl"; }
BEGIN { require "wakautils.pl"; }



#
# Optional modules
#

my ($has_encode);

if(CHARSET) # don't use Unicode at all if CHARSET is not set.
{
	eval 'use Encode qw(decode)';
	$has_encode=1 unless($@);
}



#
# Global init
#

my $query=new CGI;
my $task=$query->param("task");

my $ip=$ENV{REMOTE_ADDR};
my $oek_ip=$query->param("oek_ip");
$oek_ip=$ip unless($oek_ip);

die unless($oek_ip=~/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/);

my $tmpname=TMP_DIR.$oek_ip.'.png';

if(!$task)
{
	my $oek_parent=$query->param("oek_parent");
	my $srcinfo=$query->param("srcinfo");

	make_http_header();

	print OEKAKI_FINISH_TEMPLATE->(
		tmpname=>$tmpname,
		oek_parent=>clean_string($oek_parent),
		oek_ip=>$oek_ip,
		srcinfo=>clean_string($srcinfo),
		decodedinfo=>OEKAKI_INFO_TEMPLATE->(decode_srcinfo($srcinfo)),
	);
}
elsif($task eq "post")
{
	my $parent=$query->param("parent");
	my $name=$query->param("name");
	my $email=$query->param("email");
	my $subject=$query->param("subject");
	my $comment=$query->param("comment");
	my $password=$query->param("password");
	my $captcha=$query->param("captcha");
	my $srcinfo=$query->param("srcinfo");

	my $ua=LWP::UserAgent->new;
	my $res=$ua->request(POST WAKABA_SCRIPT_URL,
		Content_Type=>'form-data',
		Content=>[
			task=>'post',
			parent=>$parent,
			name=>$name,
			email=>$email,
			subject=>$subject,
			comment=>$comment,
			password=>$password,
			captcha=>$captcha,
			admin=>ADMIN_PASS,
			fake_ip=>$ip,
			postfix=>OEKAKI_INFO_TEMPLATE->(decode_srcinfo($srcinfo)),
			file=>[$tmpname],
		]
	);

	if($res->is_error())
	{
		print "Status: ".$res->status_line()."\n";
		print "Content-Type: text/html\n";
		print "\n";
		print $res->content();
		exit;
	}

	unlink $tmpname;

	my $c_name=$name;
	my $c_email=$email;
	my $c_password=$password;

	# set the name, email and password cookies
	make_cookies(name=>$c_name,email=>$c_email,password=>$c_password,-charset=>CHARSET); # yum!

	# forward back to the main page
	make_http_forward(WAKABA_PAGE_URL,ALTERNATE_REDIRECT);
}



sub make_http_header()
{
	print "Content-Type: ".get_xhtml_content_type(CHARSET)."\n";
	print "\n";

	$PerlIO::encoding::fallback=0x0200;
	binmode STDOUT,':encoding('.CHARSET.')' if($has_encode);
}

sub get_script_name()
{
	return $ENV{SCRIPT_NAME};
}

sub expand_filename($)
{
	my ($filename)=@_;
	return $filename if($filename=~m!^/!);
	return $filename if($filename=~m!^\w+:!);

	my ($self_path)=$ENV{SCRIPT_NAME}=~m!^(.*/)[^/]+$!;
	return $self_path.$filename;
}

sub decode_srcinfo($)
{
	my ($srcinfo)=@_;
	my @info=split /,/,$srcinfo;
	my @stat=stat $tmpname;
	my $fileage=$stat[9];
	my ($painter)=grep { $$_{painter} eq $info[1] } @{S_OEKPAINTERS()};

	return (
		time=>clean_string(pretty_age($fileage-$info[0])),
		painter=>clean_string($$painter{name}),
		source=>clean_string($info[2]),
	);
}

sub pretty_age($)
{
	my ($age)=@_;

	return "HAXORED" if($age<0);
	return $age." s" if($age<60);
	return int($age/60)." min" if($age<3600);
	return int($age/3600)." h ".int(($age%3600)/60)." min" if($age<3600*24*7);
	return "HAXORED";
}
