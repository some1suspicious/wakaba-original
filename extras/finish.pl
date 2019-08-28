#!perl

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
BEGIN { require "strings_e.pl"; }
BEGIN { require "oekaki_config.pl"; }
BEGIN { require "oekaki_strings_e.pl"; }
BEGIN { require "wakautils.pl"; }


#
# Templates
#

use constant INFO_TEMPLATE => compile_template(q{
<p><small><strong>
Oekaki post</strong> (Time: <var $time>, Painter: <var $painter><if $source>, Source: <a href="<var $path><var $source>"><var $source></a></if>)
</small></p>
});


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
	print_page(\*STDOUT,$tmpname,$oek_parent,$oek_ip,$srcinfo);
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
			postfix=>INFO_TEMPLATE->(decode_srcinfo($srcinfo)),
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
	if($has_encode)
	{
		print "Content-Type: text/html; charset=".CHARSET."\n";
	}
	else
	{
		print "Content-Type: text/html\n";
	}

	# print "Expires: ";
	print "\n";

	if($has_encode)
	{
		$PerlIO::encoding::fallback=0x0200;
		binmode STDOUT,':encoding('.CHARSET.')';
	}
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

sub print_page($$$$$)
{
	my ($file,$tmpname,$oek_parent,$oek_ip,$srcinfo)=@_;

	print $file '<html><head>';

	print $file '<title>'.TITLE.'</title>';
	print $file '<meta http-equiv="Content-Type"  content="text/html;charset='.CHARSET.'" />' if(CHARSET);
	print $file '<link rel="stylesheet" type="text/css" href="'.expand_filename(CSS_FILE).'" title="Standard stylesheet" />';
	print $file '<link rel="shortcut icon" href="'.expand_filename(FAVICON).'" />' if(FAVICON);
	print $file '<script src="'.expand_filename(JS_FILE).'"></script>'; # could be better
	print $file '</head><body>';

	print $file S_HEAD;

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
	print $file '<input type="hidden" name="task" value="post" />';
	print $file '<input type="hidden" name="oek_ip" value="'.$oek_ip.'" />';
	print $file '<input type="hidden" name="srcinfo" value="'.$srcinfo.'" />';
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
	print $file '<script>with(document.postform) {if(!name.value) name.value=get_cookie("name"); if(!email.value) email.value=get_cookie("email"); if(!password.value) password.value=get_password("password"); }</script>';

	print $file '<div align="center">';
	print $file '<img src="'.expand_filename($tmpname).'">';
	print INFO_TEMPLATE->(decode_srcinfo($srcinfo));
	print $file '</div>';

	print $file '<hr />';
	print $file S_FOOT;
	print $file '</body></html>';
}

sub decode_srcinfo($)
{
	my ($srcinfo)=@_;
	my @info=split /,/,$srcinfo;
	my @stat=stat $tmpname;
	my $fileage=$stat[9];
	my %names=S_OEKNAMES;

	return (
		time=>clean_string(pretty_age($fileage-$info[0])),
		painter=>clean_string($names{$info[1]}),
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
