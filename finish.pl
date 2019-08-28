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
BEGIN { require 'config.pl'; }
BEGIN { require 'strings_e.pl'; }
BEGIN { require 'oekaki_config.pl'; }
BEGIN { require 'oekaki_strings_e.pl'; }



#
# Optional modules
#

my ($has_unicode);

if(CHARSET) # don't use Unicode at all if CHARSET is not set.
{
	eval 'use Encode qw(decode)';
	$has_unicode=1 unless($@);
}



#
# Global init
#

my ($c_password,$c_name,$c_email);
my ($self_path);

my ($query,$action);

$query=new CGI;
$action=$query->param("action");

save_path();

my $ip=$ENV{REMOTE_ADDR};
my $oek_ip=$query->param("oek_ip");
$oek_ip=$ip unless($oek_ip);

die unless($oek_ip=~/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/);

my $tmpname=TMP_DIR.$oek_ip.'.png';

if(!$action)
{
	my $oek_parent=$query->param("oek_parent");

	make_http_header();
	print_page(\*STDOUT,$tmpname,$oek_parent);
}
elsif($action eq "post")
{
	my $parent=$query->param("parent");
	my $name=$query->param("name");
	my $email=$query->param("email");
	my $subject=$query->param("subject");
	my $comment=$query->param("comment");
	my $password=$query->param("password");
	my $captcha=$query->param("captcha");

	$name=clean_string($name);
	$email=clean_string($email);
	$subject=clean_string($subject);
	$comment=clean_string($comment);

	$comment.=OEKAKI_STAMP;

	my $ua=LWP::UserAgent->new;
	my $res=$ua->request(POST WAKABA_SCRIPT_URL,
		Content_Type=>'form-data',
		Content=>[
			action=>'post',
			parent=>$parent,
			name=>$name,
			email=>$email,
			subject=>$subject,
			comment=>$comment,
			password=>$password,
			captcha=>$captcha,
			admin=>ADMIN_PASS,
			fake_ip=>$ip,
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

	$c_name=$name;
	$c_email=$email;
	$c_password=$password;

	make_cookies(); # yum!

	# forward back to the main page
	make_http_forward(WAKABA_PAGE_URL);
}

# clean up the inputs
sub clean_string($$)
{
	my ($str)=@_;

	$str=~s/&/&amp;/g;
	$str=~s/</&lt;/g;
	$str=~s/>/&gt;/g;
	#$str=~s/"/&quot;/g;
	#$str=~s/'/&#039;/g;
	#$str=~s/,/&#44;/g;

	if(MAX_LINES and scalar(()=$str=~m/\n/g)>=MAX_LINES)
	{
		$str=~s/\n/ /g; # remove newlines
	}

	return $str;
}



sub make_http_header()
{
	if($has_unicode)
	{
		print "Content-Type: text/html; charset=".CHARSET."\n";
	}
	else
	{
		print "Content-Type: text/html\n";
	}

	# print "Expires: ";
	print "\n";

	binmode STDOUT,':encoding('.CHARSET.')'  if($has_unicode);
}

sub make_http_forward($)
{
	my ($location)=@_;

	print "Status: 301 Go West\n";
	print "Location: $location\n";
	print "Content-Type: text/html\n";
	print "\n";
	print '<html><body><a href="'.$location.'">'.$location.'</a></body></html>';
}

sub make_cookies()
{
	my ($cookie);

	$c_name="" unless(defined($c_name));
	$c_email="" unless(defined($c_email));
	$c_password="" unless(defined($c_password));

	$cookie=$query->cookie(-name=>'name',
	                       -value=>$c_name,
	                       -expires=>'+14d');
	print "Set-Cookie: $cookie\n";

	$cookie=$query->cookie(-name=>'email',
	                       -value=>$c_email,
	                       -expires=>'+14d');
	print "Set-Cookie: $cookie\n";

	$cookie=$query->cookie(-name=>'password',
	                       -value=>$c_password,
	                       -expires=>'+14d');
	print "Set-Cookie: $cookie\n";
}

sub save_path()
{
	($self_path)=$ENV{SCRIPT_NAME}=~m!^(.*/)[^/]+$!;
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
	return $self_path.$filename;
}

sub print_page($$$)
{
	my ($file,$tmpname,$oek_parent)=@_;

	print $file '<html><head>';

	print $file '<title>'.TITLE.'</title>';
	print $file '<meta http-equiv="Content-Type"  content="text/html;charset='.CHARSET.'" />' if(CHARSET);
	print $file '<link rel="stylesheet" type="text/css" href="'.expand_filename(CSS_FILE).'" title="Standard stylesheet" />';
	print $file '<link rel="shortcut icon" href="'.expand_filename(FAVICON).'" />' if(FAVICON);
	print $file '<script src="'.expand_filename(JS_FILE).'"></script>'; # could be better
	print $file '</head><body>';

	print $file '<div class="adminbar">';
	print $file '[<a href="'.expand_filename(HOME).'" target="_top">'.S_HOME.'</a>]';
	print $file ' [<a href="'.get_script_name().'?action=admin">'.S_ADMIN.'</a>]';
	print $file '</div>';

	print $file '<div class="logo">';
	print $file '<img src="'.expand_filename(TITLEIMG).'" alt="'.TITLE.'" />' if(SHOWTITLEIMG==1);
	print $file '<img src="'.expand_filename(TITLEIMG).'" onclick="this.src=this.src;" alt="'.TITLE.'" />' if(SHOWTITLEIMG==2);
	print $file '<br />' if(SHOWTITLEIMG and SHOWTITLETXT);
	print $file TITLE if(SHOWTITLETXT);
	print $file '</div><hr />';

	print $file '<div class="postarea" align="center">';
	print $file '<form name="postform" action="'.get_script_name().'" method="post" enctype="multipart/form-data">';
	print $file '<input type="hidden" name="action" value="post" />';
	print $file '<table><tbody>';
	print $file '<tr><td class="postblock" align="left">'.S_NAME.'</td><td align="left"><input type="text" name="name" size="28" /></td></tr>';
	print $file '<tr><td class="postblock" align="left">'.S_EMAIL.'</td><td align="left"><input type="text" name="email" size="28" /></td></tr>';
	print $file '<tr><td class="postblock" align="left">'.S_SUBJECT.'</td><td align="left"><input type="text" name="subject" size="35" />';
	print $file ' <input type="submit" value="'.S_SUBMIT.'" /></td></tr>';
	print $file '<tr><td class="postblock" align="left">'.S_COMMENT.'</td><td align="left"><textarea name="comment" cols="48" rows="4"></textarea></td></tr>';

	if(ENABLE_CAPTCHA)
	{
		my $key=$oek_parent?('res'.$oek_parent):'mainpage';

		print $file '<tr><td class="postblock" align="left">'.S_CAPTCHA.'</td><td><input type="text" name="captcha" size="10" />';
		print $file ' <img src="'.expand_filename(CAPTCHA_SCRIPT).'?key='.$key.'" />';
		print $file '</td></tr>';
	}

#	print $file '<tr><td class="postblock" align="left">'.S_DELPASS.'</td><td align="left"><input type="password" name="password" size="8" maxlength="8" value="'.$c_password.'" /> '.S_DELEXPL2.'</td></tr>';
	print $file '<tr><td class="postblock" align="left">'.S_DELPASS.'</td><td align="left"><input type="password" name="password" size="8" maxlength="8" /> '.S_DELEXPL.'</td></tr>';

	if($oek_parent)
	{
		print $file '<input type="hidden" name="parent" value="'.$oek_parent.'" />';
		print $file '<tr><td class="postblock" align="left">'.S_OEKIMGREPLY.'</td>';
		print $file '<td align="left">'.sprintf(S_OEKREPEXPL,expand_filename(RES_DIR.$oek_parent.PAGE_EXT),$oek_parent).'</td></tr>';
	}

	print $file '<tr><td colspan="2">';
	print $file '<div align="left" class="rules">'.S_RULES.'</div></td></tr>';
	print $file '</tbody></table></form></div><hr />';
	print $file '<script>with(document.postform) {name.value=get_cookie("name"); email.value=get_cookie("email"); password.value=get_password("password"); }</script>';

	print $file '<div align="center"><img src="'.expand_filename($tmpname).'"></div>';

	print $file '<hr /><div class="footer">'.S_FOOT.'</div>';
	print $file '</body></html>';
}
