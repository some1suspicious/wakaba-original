#!/usr/bin/perl

use CGI::Carp qw(fatalsToBrowser);

use strict;

use CGI;
use DBI;
use File::Copy;


#
# Import settings
#

use lib '.';
BEGIN { require 'config.pl'; }
BEGIN { require 'strings_e.pl'; }
BEGIN { require 'futaba_style.pl'; }
BEGIN { require 'filetypes_none.pl'; }

my %filetypes=%filetypes::filetypes;



#
# Optional modules
#

my ($has_md5,$has_magick,$has_gd,$has_unicode);

eval 'use Digest::MD5 qw(md5_hex)';
$has_md5=1 unless($@);
eval 'use Image::Magick';
$has_magick=1 unless($@);
#eval 'use ...';
#$has_gd=1 unless($@);

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

my ($dbh);

$dbh=DBI->connect(SQL_DBI_SOURCE,SQL_USERNAME,SQL_PASSWORD,{AutoCommit=>1}) or make_error(S_SQLCONF);

save_cookies();
save_path();

# check for admin table
init_admin_database() if(!table_exists(SQL_ADMIN_TABLE));

if(!table_exists(SQL_TABLE)) # check for comments table
{
	do_nuke_database(ADMIN_PASS);
}
elsif(!$action)
{
	make_http_forward(HTML_SELF);
}
elsif($action eq "post")
{
	my ($parent,$name,$email,$subject,$comment,$file,$password,$nofile,$captcha,$admin);

	$parent=$query->param("parent");
	$name=$query->param("name");
	$email=$query->param("email");
	$subject=$query->param("subject");
	$comment=$query->param("comment");
	$file=$query->param("file");
	$password=$query->param("password");
	$nofile=$query->param("nofile");
	$captcha=$query->param("captcha");
	$admin=$query->param("admin");

	post_stuff($parent,$name,$email,$subject,$comment,$file,$password,$nofile,$captcha,$admin);
}
elsif($action eq "delete")
{
	my ($password,$fileonly,$admin,@posts);

	$password=$query->param("password");
	$fileonly=$query->param("fileonly");
	$admin=$query->param("admin");
	@posts=$query->param("delete");

	delete_stuff($password,$fileonly,$admin,@posts);
}
elsif($action eq "admin")
{
	make_admin_login();
}
elsif($action eq "mpanel")
{
	my ($admin);
	$admin=$query->param("admin");
	make_admin_post_panel($admin);
}
elsif($action eq "deleteall")
{
	my ($admin,$ip,$mask);
	$admin=$query->param("admin");
	$ip=$query->param("ip");
	$mask=$query->param("mask");
	delete_all($admin,parse_range($ip,$mask));
}
elsif($action eq "bans")
{
	my ($admin);
	$admin=$query->param("admin");
	make_admin_ban_panel($admin);
}
elsif($action eq "addip")
{
	my ($admin,$type,$comment,$ip,$mask);
	$admin=$query->param("admin");
	$type=$query->param("type");
	$comment=$query->param("comment");
	$ip=$query->param("ip");
	$mask=$query->param("mask");
	add_admin_entry($admin,$type,$comment,parse_range($ip,$mask),'');
}
elsif($action eq "addstring")
{
	my ($admin,$type,$string,$comment);
	$admin=$query->param("admin");
	$type=$query->param("type");
	$string=$query->param("string");
	$comment=$query->param("comment");
	add_admin_entry($admin,$type,$comment,0,0,$string);
}
elsif($action eq "removeban")
{
	my ($admin,$num);
	$admin=$query->param("admin");
	$num=$query->param("num");
	remove_admin_entry($admin,$num);
}
elsif($action eq "mpost")
{
	my ($admin);
	$admin=$query->param("admin");
	make_admin_post($admin);
}
elsif($action eq "rebuild")
{
	my ($admin);
	$admin=$query->param("admin");
	do_rebuild_cache($admin);
}
elsif($action eq "nuke")
{
	my ($admin);
	$admin=$query->param("admin");
	do_nuke_database($admin);
}

$dbh->disconnect();





#
# Cache page creation
#

sub build_cache()
{
	my ($sth,$row,@thread);
	my (@thread,@threads,$page,$total);

	$page=0;

	# grab all posts, in thread order
	$sth=$dbh->prepare("SELECT * FROM ".SQL_TABLE." ORDER BY lasthit DESC,num ASC") or make_error(S_SQLFAIL);
	$sth->execute() or make_error(S_SQLFAIL);

	$row=get_decoded_hashref($sth);

	if(!$row) # no posts on the board!
	{
		build_cache_page(0,1); # make an empty page 0
	}
	else
	{
		@thread=($row);
		$total=get_page_count();

		while($row=get_decoded_hashref($sth))
		{
			if(!$$row{parent})
			{
				push @threads,[@thread];

				if(scalar(@threads)==IMAGES_PER_PAGE)
				{
					build_cache_page($page,$total,@threads);
					@threads=();
					$page++;
				}

				@thread=($row); # start new thread
			}
			else
			{
				push @thread,$row;
			}
		}
		push @threads,[@thread];
		build_cache_page($page,$total,@threads);
	}

	# check for and remove old pages
	$page++;

	while(-e $page.PAGE_EXT)
	{
		unlink $page.PAGE_EXT;
		$page++;
	}
}

sub build_cache_page($$@)
{
	my ($page,$total,@threads)=@_;
	my ($filename,$tmpname);

	if($page==0) { $filename=HTML_SELF; }
	else { $filename=$page.PAGE_EXT; }

	if(USE_TEMPFILES)
	{
		$tmpname='tmp'.int(rand(1000000000));

		open (PAGE,">$tmpname") or make_error(S_NOTWRITE);
		binmode PAGE,':encoding('.CHARSET.')' if($has_unicode);
		print_page(\*PAGE,$page,$total,@threads);
		close PAGE;

		make_error(S_NOTWRITE) unless(rename $tmpname,$filename);
	}
	else
	{
		open (PAGE,">$filename") or make_error(S_NOTWRITE);
		binmode PAGE,':encoding('.CHARSET.')' if($has_unicode);
		print_page(\*PAGE,$page,$total,@threads);
		close PAGE;
	}
}

sub build_thread_cache($)
{
	my ($thread)=@_;
	my ($sth,$row,@thread);
	my ($filename,$tmpname);

	$sth=$dbh->prepare("SELECT * FROM ".SQL_TABLE." WHERE num=? OR parent=? ORDER BY num ASC;") or make_error(S_SQLFAIL);
	$sth->execute($thread,$thread) or make_error(S_SQLFAIL);

	while($row=get_decoded_hashref($sth)) { push(@thread,$row); }

	make_error(S_NOTHREADERR) if($thread[0]{parent});

	$filename=RES_DIR.$thread.PAGE_EXT;

	if(USE_TEMPFILES)
	{
		$tmpname=RES_DIR.'tmp'.int(rand(1000000000));

		open (PAGE,">$tmpname") or make_error(S_NOTWRITE);
		binmode PAGE,':encoding('.CHARSET.')' if($has_unicode);
		print_reply(\*PAGE,@thread);
		close PAGE;

		rename $tmpname,$filename;
	}
	else
	{
		open (PAGE,">$filename") or make_error(S_NOTWRITE);
		binmode PAGE,':encoding('.CHARSET.')' if($has_unicode);
		print_reply(\*PAGE,@thread);
		close PAGE;
	}
}

sub build_thread_cache_all()
{
	my ($sth,$row,@thread);

	$sth=$dbh->prepare("SELECT num FROM ".SQL_TABLE." WHERE parent=0;") or make_error(S_SQLFAIL);
	$sth->execute() or make_error(S_SQLFAIL);

	while($row=$sth->fetchrow_arrayref())
	{
		build_thread_cache($$row[0]);
	}
}



#
# Posting
#

sub post_stuff($$$$$$$$$$$)
{
	my ($parent,$name,$email,$subject,$comment,$file,$password,$nofile,$captcha,$admin)=@_;
	my ($sth,$row,$ip,$numip,$host,$whitelisted,$trip,$time,$date,$lasthit);
	my ($filename,$size,$md5,$width,$height,$thumbnail,$tn_width,$tn_height);

	# get a timestamp for future use
	$time=time();

	# check that the request came in as a POST, or from the command line
	make_error(S_UNJUST) if($ENV{REQUEST_METHOD} and $ENV{REQUEST_METHOD} ne "POST");

	# see what kind of posting is allowed
	unless($admin eq ADMIN_PASS)
	{
		if($parent)
		{
			make_error(S_NOTALLOWED) if($file and !ALLOW_IMAGE_REPLIES);
			make_error(S_NOTALLOWED) if(!$file and !ALLOW_TEXT_REPLIES);
		}
		else
		{
			make_error(S_NOTALLOWED) if($file and !ALLOW_IMAGES);
			make_error(S_NOTALLOWED) if(!$file and !ALLOW_TEXTONLY);
		}
	}

	# check for weird characters
	make_error(S_UNUSUAL) if($parent=~/[^0-9]/);
	make_error(S_UNUSUAL) if(length($parent)>10);
	make_error(S_UNUSUAL) if($name=~/[\n\r]/);
	make_error(S_UNUSUAL) if($email=~/[\n\r]/);
	make_error(S_UNUSUAL) if($subject=~/[\n\r]/);
	#make_error(S_UNUSUAL) if(length($url)>10);

	# check for excessive amounts of text
	make_error(S_TOOLONG) if(length($name)>MAX_FIELD_LENGTH);
	make_error(S_TOOLONG) if(length($email)>MAX_FIELD_LENGTH);
	make_error(S_TOOLONG) if(length($subject)>MAX_FIELD_LENGTH);
	make_error(S_TOOLONG) if(length($comment)>MAX_COMMENT_LENGTH);

	# check to make sure the user selected a file, or clicked the checkbox
	make_error(S_NOPIC) if(!$parent and !$file and !$nofile);

	# check for empty reply or empty text-only post
	make_error(S_NOTEXT) if($comment=~/^\s*$/ and !$file);

	# get file size, and check for limitations.
	$size=get_file_size($file) if($file);

	# find hostname
	$ip=$ENV{REMOTE_ADDR};
	#$host = gethostbyaddr($ip);
	$numip=dot_to_dec($ip);

	# check if IP is whitelisted
	$whitelisted=is_whitelisted($numip);

	# check captcha - should whitelists affect captcha?
	check_captcha($captcha,$ip,$parent) if(ENABLE_CAPTCHA and $admin ne ADMIN_PASS);

	# check for bans
	ban_check($numip,$name,$subject,$comment) unless($whitelisted);

	# proxy check
	proxy_check($ip) unless($whitelisted);

	# check if thread exists, and get lasthit value
	if($parent)
	{
		$lasthit=get_lasthit($parent);
		make_error(S_NOTHREADERR) unless($lasthit);
	}
	else
	{
		$lasthit=$time;
	}

	# set up cookies
	$c_name=$name;
	$c_email=$email;
	$c_password=$password;

	# process the tripcode
	($name,$trip)=process_tripcode($name);

	# clean up the inputs
	$name=clean_string($name,$admin);
	$email=clean_string($email,$admin);
	$subject=clean_string($subject,$admin);
	$comment=clean_string($comment,$admin);

	# format comment
	$comment=format_comment($comment);

	# insert default values for empty fields
	$parent=0 unless($parent);
	$name=S_ANONAME unless($name||$trip);
	$subject=S_ANOTITLE unless($subject);
	$comment=S_ANOTEXT unless($comment);

	# flood protection - must happen after inputs have been cleaned up
	flood_check($ip,$time,$comment,$file);

	# Manager and deletion stuff - duuuuuh?

	# generate date
	$date=make_date($time,DATE_STYLE);

	# generate ID code if enabled
	$date.=' ID:'.make_id_code($ip,$time,$email) if(DISPLAY_ID);

	# copy file, do checksums, make thumbnail, etc
	($filename,$md5,$width,$height,$thumbnail,$tn_width,$tn_height)=process_file($file,$time) if($file);

	# finally, write to the database
	$sth=$dbh->prepare("INSERT INTO ".SQL_TABLE." VALUES(null,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);") or make_error(S_SQLFAIL);
	$sth->execute($parent,$time,$lasthit,dot_to_dec($ip),
	$date,$name,$trip,$email,$subject,$password,$comment,
	$filename,$size,$md5,$width,$height,$thumbnail,$tn_width,$tn_height) or make_error(S_SQLFAIL);

	if($parent) # bumping
	{
		# check for sage, or too many replies
		unless($email=~/sage/i or count_replies($parent)>MAX_RES)
		{
			$sth=$dbh->prepare("UPDATE ".SQL_TABLE." SET lasthit=$time WHERE num=? OR parent=?;") or make_error(S_SQLFAIL);
			$sth->execute($parent,$parent) or make_error(S_SQLFAIL);
		}
	}

	# remove old threads from the database
	trim_database();

	# update the cached HTML pages
	build_cache();

	# update the individual thread cache
	if($parent) { build_thread_cache($parent); }
	else # must find out what our new thread number is
	{
		if($filename)
		{
			$sth=$dbh->prepare("SELECT num FROM ".SQL_TABLE." WHERE image=?;") or make_error(S_SQLFAIL);
			$sth->execute($filename) or make_error(S_SQLFAIL);
		}
		else
		{
			$sth=$dbh->prepare("SELECT num FROM ".SQL_TABLE." WHERE timestamp=? AND comment=?;") or make_error(S_SQLFAIL);
			$sth->execute($time,$comment) or make_error(S_SQLFAIL);
		}
		my $num=($sth->fetchrow_array())[0];

		if($num)
		{
			build_thread_cache($num);
		}
	}

	# set the name, email and password cookies
	make_cookies(); # yum!

	# forward back to the main page
	make_http_forward(HTML_SELF);
}

sub is_whitelisted($)
{
	my ($numip)=@_;
	my ($sth);

	$sth=$dbh->prepare("SELECT count(*) FROM ".SQL_ADMIN_TABLE." WHERE type='whitelist' AND ? & ival2 = ival1 & ival2;") or make_error(S_SQLFAIL);
	$sth->execute($numip) or make_error(S_SQLFAIL);

	return 1 if(($sth->fetchrow_array())[0]);

	return 0;
}

sub ban_check($$$$)
{
	my ($numip,$name,$subject,$comment)=@_;
	my ($sth);

	$sth=$dbh->prepare("SELECT count(*) FROM ".SQL_ADMIN_TABLE." WHERE type='ipban' AND ? & ival2 = ival1 & ival2;") or make_error(S_SQLFAIL);
	$sth->execute($numip) or make_error(S_SQLFAIL);

	make_error(S_BADHOST) if(($sth->fetchrow_array())[0]);

	$sth=$dbh->prepare("SELECT count(*) FROM ".SQL_ADMIN_TABLE." WHERE type='wordban' AND ? LIKE '%' || sval1 || '%';") or make_error(S_SQLFAIL);
	$sth->execute($comment) or make_error(S_SQLFAIL);

	make_error(S_STRREF) if(($sth->fetchrow_array())[0]);

	# etc etc etc

	return(0);
}

sub flood_check($$$$)
{
	my ($ip,$time,$comment,$file)=@_;
	my ($sth,$maxtime);

	if($file)
	{
		# check for to quick file posts
		$maxtime=$time-(RENZOKU2);
		$sth=$dbh->prepare("SELECT count(*) FROM ".SQL_TABLE." WHERE ip=? AND timestamp>$maxtime;") or make_error(S_SQLFAIL);
		$sth->execute($ip) or make_error(S_SQLFAIL);
		make_error(S_RENZOKU2) if(($sth->fetchrow_array())[0]);
	}
	else
	{
		# check for too quick replies or text-only posts
		$maxtime=$time-(RENZOKU);
		$sth=$dbh->prepare("SELECT count(*) FROM ".SQL_TABLE." WHERE ip=? AND timestamp>$maxtime;") or make_error(S_SQLFAIL);
		$sth->execute($ip) or make_error(S_SQLFAIL);
		make_error(S_RENZOKU) if(($sth->fetchrow_array())[0]);

		# check for repeated messages
		$maxtime=$time-(RENZOKU3);
		$sth=$dbh->prepare("SELECT count(*) FROM ".SQL_TABLE." WHERE ip=? AND comment=? AND timestamp>$maxtime;") or make_error(S_SQLFAIL);
		$sth->execute($ip,$comment) or make_error(S_SQLFAIL);
		make_error(S_RENZOKU3) if(($sth->fetchrow_array())[0]);
	}
}

sub proxy_check($)
{
	my ($ip)=@_;

	for my $port (PROXY_CHECK)
	{
		# needs to be implemented
		# make_error(sprintf S_PROXY,$port);
	}
}

sub get_lasthit($)
{
	my ($thread)=@_;
	my ($sth);

	$sth=$dbh->prepare("SELECT lasthit FROM ".SQL_TABLE." WHERE num=? AND parent=0;") or make_error(S_SQLFAIL);
	$sth->execute($thread) or make_error(S_SQLFAIL);

	return ($sth->fetchrow_array())[0];
}

sub process_tripcode($)
{
	my ($name,$hash)=@_;

	if($name=~/^([^\#!]*)[\#!](.*)$/)
	{
		my ($namepart,$trip)=($1,$2);
		my ($salt,$hash);

		($salt)=($trip."H.")=~/^.(..)/;
		$salt=~s/[^\.-z]/./g;
		$salt=~tr/:;<=>?@[\\]^_`/ABCDEFGabcdef/; 

		return ($namepart,substr crypt($trip,$salt),-10);
	}
	return ($name,"");
}

sub clean_string($$)
{
	my ($str,$admin)=@_;

	if($has_unicode)
	{
		$str=decode(CHARSET,$str);

		# decode any unicode entities
		#$str=~s/&\#([0-9]+);/chr($1)/g;
	}

	$str=~s/^\s*//; # remove preceeding whitespace
	$str=~s/\s*$//; # remove traling whitespace


	if($admin ne ADMIN_PASS) # admins can use tags
	{
		$str=~s/&/&amp;/g;
		$str=~s/</&lt;/g;
		$str=~s/>/&gt;/g;
		#$str=~s/"/&quot;/g;
		#$str=~s/'/&#039;/g;
		#$str=~s/,/&#44;/g;
	}

	# repair unicode entities if we haven't converted them earlier
#	$str=~s/&amp;(\#[0-9]+;)/&$1/g unless($has_unicode);
	# repair unicode entities
	$str=~s/&amp;(\#[0-9]+;)/&$1/g;

	return $str;
}

sub format_comment($$)
{
	my ($comment,$admin)=@_;
	# fix newlines
	$comment=~s/\r\n/\n/g;
	$comment=~s/\r/\n/g;

	# hmm, what about this weirdness?
#// Continuous lines
#$com = ereg_replace("\n((!@| )*\n){3,}","\n",$com);
#	$comment=~s/\n(\s*?\n){3,}/\n\n/sg;

	# make URLs into links - is this magic or what
	$comment=~s!(http://\S*?(\(\S*?\)\S*?)?)(\)|\.?\s|$)!<a href="$1">$1</a>$3!sgi;

	# colour quoted sections
	$comment=~s!^(&gt;.*)$!<span class="unkfunc">$1</span>!gm;

	# count number of newlines if MAX_LINES is not 0 - wow, magic. also, admin posts can be longer.
	if($admin ne ADMIN_PASS and MAX_LINES and scalar(()=$comment=~m/\n/g)>=MAX_LINES)
	{
		$comment=~s/\n/ /g; # remove newlines
	}
	else
	{
		$comment=~s!\n!<br />!g; # replace newlines with <br />
	}

	return $comment;
}

sub make_id_code($$$)
{
	my ($ip,$time,$email)=@_;

	return EMAIL_ID if($email and DISPLAY_ID==1);

	my @gmt=gmtime $time+9*60*60; # weird time offset copied from futaba
	my $date=sprintf '%04d%02d%02d',$gmt[5]+1900,$gmt[4]+1,$gmt[3];

	if($has_md5)
	{
		return substr(crypt(md5_hex($ip.'id'.$date),'id'),-8);
	}
	else
	{
		return substr(crypt($ip.'id'.$date,'id'),-8);
	}
}

sub check_captcha($$$)
{
	my ($captcha,$ip,$parent)=@_;
	my ($key,$word);

	$key=get_captcha_key($parent);
	$word=get_captcha_word($ip,$key);

	make_error(S_NOCAPTCHA) unless($word);
	make_error(S_BADCAPTCHA) if($word ne $captcha);

	delete_captcha_word($ip,$key); # should the captcha word be deleted on an UNSUCCESSFUL try, too, maybe?
}

sub get_captcha_key($)
{
	my ($parent)=@_;

	return 'res'.$parent if($parent);
	return 'mainpage';
}

sub get_captcha_word($$)
{
	my ($ip,$key)=@_;
	my ($sth,$row);

	$sth=$dbh->prepare("SELECT word FROM ".SQL_CAPTCHA_TABLE." WHERE ip=? AND pagekey=?;") or return undef;
	$sth->execute($ip,$key) or return undef; # the captcha script creates the database, so it might not exist yet
	return $$row[0] if($row=$sth->fetchrow_arrayref());

	return undef;
}

sub delete_captcha_word($$)
{
	my ($ip,$key)=@_;
	my ($sth,$row);

	$sth=$dbh->prepare("DELETE FROM ".SQL_CAPTCHA_TABLE." WHERE ip=? AND pagekey=?;") or return;
	$sth->execute($ip,$key) or return;
}

sub get_file_size($)
{
	my ($file)=@_;
	my (@filestats,$size);

	@filestats=stat $file;
	$size=$filestats[7];

	make_error(S_TOOBIG) if($size>MAX_KB*1024);
	make_error(S_TOOBIGORNONE) if($size==0); # check for small files, too?

	return($size);
}

sub process_file($$)
{
	my ($file,$time)=@_;
	my ($filename,$md5,$width,$height,$thumbnail,$tn_width,$tn_height);
	my ($sth,$ext,$filebase,$buffer,$md5ctx);

	# make sure to read file in binary mode on platforms that care about such things
	binmode $file;

	# analyze file and check that it's in a supported format
	($ext,$width,$height)=analyze_image($file);

	make_error(S_BADFORMAT) if(!ALLOW_UNKNOWN and !$width and !$filetypes{$ext});
	make_error(S_TOOBIG) if(MAX_IMAGE_WIDTH and $width>MAX_IMAGE_WIDTH);
	make_error(S_TOOBIG) if(MAX_IMAGE_HEIGHT and $height>MAX_IMAGE_HEIGHT);
	make_error(S_TOOBIG) if(MAX_IMAGE_PIXELS and $width*$height>MAX_IMAGE_PIXELS);

	if($filetypes{$ext}) # externally defined filetype - keep the name
	{
		$filebase=$file;
		$filebase=~s!^.*(\\|/)!!; # cut off any directory in filename
		$filename=IMG_DIR.$filebase;

		make_error(S_DUPE) if(-e $filename); # verify no name clash
	}
	else # generate random filename - fudges the microseconds
	{
		$filebase=$time.sprintf("%03d",int(rand(1000)));
		$filename=IMG_DIR.$filebase.'.'.$ext;
	}

	# prepare MD5 checksum if the Digest::MD5 module is available
	$md5ctx=Digest::MD5->new if($has_md5);

	# copy file
	open (OUTFILE,">>$filename") or make_error(S_NOTWRITE);
	binmode OUTFILE;
	while (read($file,$buffer,1024)) # should the buffer be larger?
	{
		print OUTFILE $buffer;
		$md5ctx->add($buffer) if($has_md5);
	}
	close $file;
	close OUTFILE;

	if($has_md5) # if we have Digest::MD5, get the checksum
	{
		$md5=$md5ctx->hexdigest();
	}
	else # try using the md5sum command
	{
		my $md5sum=`md5sum $filename`;
		($md5)=$md5sum=~/^([0-9a-f]+)/ unless($?);
	}

	if($md5) # if we managed to generate an md5 checksum, check for duplicate files
	{
		$sth=$dbh->prepare("SELECT * FROM ".SQL_TABLE." WHERE md5=?;") or make_error(S_SQLFAIL);
		$sth->execute($md5) or make_error(S_SQLFAIL);

		if(($sth->fetchrow_array())[0])
		{
			unlink $filename; # make sure to remove the file
			make_error(S_DUPE);
		}
	}

	# thumbnail

	$thumbnail=THUMB_DIR.$filebase."s.jpg";

	if(!$width) # unsupported file
	{
		if($filetypes{$ext}) # externally defined filetype
		{
			my ($tn_ext);

			open THUMBNAIL,$filetypes{$ext};
			binmode THUMBNAIL;
			($tn_ext,$tn_width,$tn_height)=analyze_image(\*THUMBNAIL);
			close THUMBNAIL;

			if(!$tn_width) # was that icon file really there?
			{
				$thumbnail=undef;
			}
			else
			{
				$thumbnail=THUMB_DIR.$filebase."_s.".$tn_ext;
				make_error(S_NOTWRITE) unless(copy($filetypes{$ext},$thumbnail));
			}
		}
		else
		{
			$thumbnail=undef;
		}
	}
	elsif($width<=MAX_W and $height<=MAX_H) # small enough to display
	{
		$tn_width=$width;
		$tn_height=$height;

		if(THUMBNAIL_SMALL)
		{
			$thumbnail=undef unless(make_thumbnail($filename,$thumbnail,$tn_width,$tn_height));
		}
		else
		{
			$thumbnail=$filename;
		}
	}
	else
	{
		$tn_width=MAX_W;
		$tn_height=int(($height*(MAX_W))/$width);

		if($tn_height>MAX_H)
		{
			$tn_width=int(($width*(MAX_H))/$height);
			$tn_height=MAX_H;
		}

		$thumbnail=undef unless(make_thumbnail($filename,$thumbnail,$tn_width,$tn_height));
	}

	return($filename,$md5,$width,$height,$thumbnail,$tn_width,$tn_height);
}



#
# Deleting
#

sub delete_stuff($$$@)
{
	my ($password,$fileonly,$admin,@posts)=@_;
	my ($post);

	make_error(S_WRONGPASS) if($admin and $admin ne ADMIN_PASS); # check admin password
	make_error(S_BADDELPASS) unless($password or $admin); # refuse empty password immediately

	# no password means delete always
	$password="" if($admin); 

	foreach $post (@posts)
	{
		delete_post($post,$password,$fileonly);
	}

	# update the cached HTML pages
	build_cache();

	if($admin)
	{ make_http_forward($ENV{SCRIPT_NAME}."?admin=$admin&action=mpanel"); }
	else
	{ make_http_forward(HTML_SELF); }
}

sub delete_post($$$)
{
	my ($post,$password,$fileonly)=@_;
	my ($sth,$row,$res,$reply);

	$sth=$dbh->prepare("SELECT * FROM ".SQL_TABLE." WHERE num=?;") or make_error(S_SQLFAIL);
	$sth->execute($post) or make_error(S_SQLFAIL);

	if($row=$sth->fetchrow_hashref())
	{
		make_error(S_BADDELPASS) if($password and $$row{password} ne $password);

		unless($fileonly)
		{
			# remove files from comment and possible replies
			$sth=$dbh->prepare("SELECT image,thumbnail FROM ".SQL_TABLE." WHERE num=? OR parent=?") or make_error(S_SQLFAIL);
			$sth->execute($post,$post) or make_error(S_SQLFAIL);

			while($res=$sth->fetchrow_hashref())
			{
				unlink $$res{image}; # delete images if they exist
				unlink $$res{thumbnail};
			}

			# remove post and possible replies
			$sth=$dbh->prepare("DELETE FROM ".SQL_TABLE." WHERE num=? OR parent=?;") or make_error(S_SQLFAIL);
			$sth->execute($post,$post) or make_error(S_SQLFAIL);
		}
		else # remove just the image and update the database
		{
			if($$row{image})
			{
				# remove images
				unlink $$row{image};
				unlink $$row{thumbnail};

				$sth=$dbh->prepare("UPDATE ".SQL_TABLE." SET size=0,md5=null,thumbnail=null WHERE num=?;") or make_error(S_SQLFAIL);
				$sth->execute($post) or make_error(S_SQLFAIL);
			}
		}

		# fix up the thread cache
		if(!$$row{parent})
		{
			unless($fileonly) # removing an entire thread
			{
				unlink RES_DIR.$$row{num}.PAGE_EXT;
			}
			else # removing parent image
			{
				build_thread_cache($$row{num});
			}
		}
		else # removing a reply, or a reply's image
		{
			build_thread_cache($$row{parent});
		}
	}
}



#
# Admin interface
#

sub make_admin_login()
{
	make_http_header();

	print_admin_login(\*STDOUT);
}

sub make_admin_post_panel($)
{
	my ($admin)=@_;
	my ($sth,$row,@posts);

	make_error(S_WRONGPASS) if($admin ne ADMIN_PASS); # check admin password

	$sth=$dbh->prepare("SELECT * FROM ".SQL_TABLE." ORDER BY lasthit DESC,num ASC;") or make_error(S_SQLFAIL);
	$sth->execute() or make_error(S_SQLFAIL);
	while($row=get_decoded_hashref($sth)) { push(@posts,$row); }

	make_http_header();
	print_admin_post_panel(\*STDOUT,$admin,@posts);
}

sub make_admin_ban_panel($)
{
	my ($admin)=@_;
	my ($sth,$row,@bans);

	make_error(S_WRONGPASS) if($admin ne ADMIN_PASS); # check admin password

	$sth=$dbh->prepare("SELECT * FROM ".SQL_ADMIN_TABLE." WHERE type='ipban' OR type='wordban' OR type='whitelist' ORDER BY type ASC,num ASC;") or make_error(S_SQLFAIL);
	$sth->execute() or make_error(S_SQLFAIL);
	while($row=get_decoded_hashref($sth)) { push(@bans,$row); }

	make_http_header();
	print_admin_ban_panel(\*STDOUT,$admin,@bans);
}

sub make_admin_post($)
{
	my ($admin)=@_;

	make_error(S_WRONGPASS) if($admin ne ADMIN_PASS); # check admin password

	make_http_header();
	print_admin_post(\*STDOUT,$admin);
}

sub do_rebuild_cache($)
{
	my ($admin)=@_;

	make_error(S_WRONGPASS) if($admin ne ADMIN_PASS); # check admin password

	unlink glob RES_DIR.'*';

	build_cache();
	build_thread_cache_all();

	make_http_forward(HTML_SELF);
}

sub add_admin_entry($$$$$$)
{
	my ($admin,$type,$comment,$ival1,$ival2,$sval1)=@_;
	my ($sth);

	make_error(S_WRONGPASS) if($admin ne ADMIN_PASS); # check admin password

	$comment=clean_string($comment,'');

	$sth=$dbh->prepare("INSERT INTO ".SQL_ADMIN_TABLE." VALUES(null,?,?,?,?,?);") or make_error(S_SQLFAIL);
	$sth->execute($type,$comment,$ival1,$ival2,$sval1) or make_error(S_SQLFAIL);

	make_http_forward(get_script_name()."?admin=$admin&action=bans");
}

sub remove_admin_entry($$)
{
	my ($admin,$num)=@_;
	my ($sth);

	make_error(S_WRONGPASS) if($admin ne ADMIN_PASS); # check admin password

	$sth=$dbh->prepare("DELETE FROM ".SQL_ADMIN_TABLE." WHERE num=?;") or make_error(S_SQLFAIL);
	$sth->execute($num) or make_error(S_SQLFAIL);

	make_http_forward(get_script_name()."?admin=$admin&action=bans");
}

sub delete_all($$$)
{
	my ($admin,$ip,$mask)=@_;
	my ($sth,$row,@posts);

	make_error(S_WRONGPASS) if($admin ne ADMIN_PASS); # check admin password

	$sth=$dbh->prepare("SELECT num FROM ".SQL_TABLE." WHERE ip & ? = ?;") or make_error(S_SQLFAIL);
	$sth->execute($mask,$ip&$mask) or make_error(S_SQLFAIL);
	while($row=$sth->fetchrow_hashref()) { push(@posts,$$row{num}); }

	delete_stuff('',0,$admin,@posts);
}

sub do_nuke_database($)
{
	my ($admin)=@_;

	make_error(S_WRONGPASS) if($admin ne ADMIN_PASS); # check admin password
	
	init_database();

	# remove images, thumbnails and threads
	unlink glob IMG_DIR.'*';
	unlink glob THUMB_DIR.'*';
	unlink glob RES_DIR.'*';

	build_cache();

	make_http_forward(HTML_SELF);
}



#
# Page creation utils
#

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

	print "Status: 302 Go West\n";
	print "Location: $location\n";
	print "Content-Type: text/html\n";
	print "\n";
	print '<html><body><a href="'.$location.'">'.$location.'</a></body></html>';
}

sub make_error($)
{
	my ($error)=@_;

	print "Status: 500 $error\n";
	print "Content-Type: text/html\n";
	print "\n";

	print_error(\*STDOUT,$error);

	$dbh->{Warn}=0;
	$dbh->disconnect();

	if(ERRORLOG) # could print even more data, really.
	{
		open ERRORFILE,'>>'.ERRORLOG;
		print ERRORFILE $error."\n";
		print ERRORFILE $ENV{HTTP_USER_AGENT}."\n";
		print ERRORFILE "**\n";
		close ERRORFILE;
	}

	# delete temp files

	exit;
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

sub save_cookies()
{
	$c_name=$query->cookie("name");
	$c_email=$query->cookie("email");
	$c_password=$query->cookie("password");

	$c_name="" unless($c_name);
	$c_email="" unless($c_email);
	$c_password=substr(crypt(substr(rand(),2),"pw"),-8) unless($c_password);
}

sub save_path()
{
	($self_path)=$ENV{SCRIPT_NAME}=~m!^(.*/)[^/]+$!;
}

sub get_script_name()
{
	return $ENV{SCRIPT_NAME};
}

sub get_reply_link($)
{
	my ($thread)=@_;

	return expand_filename(RES_DIR.$thread.PAGE_EXT);
}

sub get_page_links($)
{
	my ($total)=@_;
	my (@pages,$i);

	$pages[0]=expand_filename(HTML_SELF);
	for($i=1;$i<$total;$i++) { $pages[$i]=expand_filename($i.PAGE_EXT); }

	return @pages;
}

sub get_page_count()
{
	return int((count_threads()+IMAGES_PER_PAGE-1)/IMAGES_PER_PAGE);
}

sub expand_filename($)
{
	my ($filename)=@_;
	return $filename if($filename=~m!^/!);
	return $filename if($filename=~m!^\w+:!);
	return $self_path.$filename;
}

sub make_date($)
{
	my ($time,$style)=@_;

	if($style==0)
	{
		my @ltime=localtime($time);

		return sprintf("%02d/%02d/%02d(%s)%02d:%02d",
		$ltime[5]-100,$ltime[4]+1,$ltime[3],(S_WEEKDAYS)[$ltime[6]],$ltime[2],$ltime[1]);
	}
	elsif($style==1)
	{
		return scalar(localtime($time));
	}
	elsif($style==2)
	{
		my @ltime=localtime($time);

		return sprintf("%02d/%02d %02d:%02d",
		$ltime[4]+1,$ltime[3],$ltime[2],$ltime[1]);
	}
}

sub dot_to_dec($)
{
	return unpack('N',pack('C4',split(/\./, $_[0]))); # wow, magic.
}

sub dec_to_dot($)
{
	return join('.',unpack('C4',pack('N',$_[0])));
}

sub parse_range($$)
{
	my ($ip,$mask)=@_;

	$ip=dot_to_dec($ip);

	if($mask=~/^\d+\.\d+\.\d+\.\d+$/) { $mask=dot_to_dec($mask); }
	elsif($mask=~/(\d+)/) { $mask=(~((1<<$1)-1)); }
	else { $mask=0xffffffff; }

	return ($ip,$mask);
}




#
# Database utils
#

sub init_database()
{
	my ($sth);

	$sth=$dbh->do("DROP TABLE ".SQL_TABLE.";") if(table_exists(SQL_TABLE));
	$sth=$dbh->prepare("CREATE TABLE ".SQL_TABLE." (".

	"num ".get_sql_autoincrement().",".	# Post number, auto-increments
	"parent INTEGER,".			# Parent post for replies in threads. For original posts, must be set to 0 (and not null)
	"timestamp INTEGER,".			# Timestamp in seconds for when the post was created
	"lasthit INTEGER,".			# Last activity in thread. Must be set to the same value for BOTH the original post and all replies!
	"ip TEXT,".				# IP number of poster

	"date TEXT,".				# The date, as a string
	"name TEXT,".				# Name of the poster
	"trip TEXT,".				# Tripcode (encoded)
	"email TEXT,".				# Email address
	"subject TEXT,".			# Subject
	"password TEXT,".			# Deletion password (in plaintext) 
	"comment TEXT,".			# Comment text, HTML encoded.

	"image TEXT,".				# Image filename with path and extension (IE, src/1081231233721.jpg)
	"size INTEGER,".			# File size in bytes
	"md5 TEXT,".				# md5 sum in hex
	"width INTEGER,".			# Width of image in pixels
	"height INTEGER,".			# Height of image in pixels
	"thumbnail TEXT,".			# Thumbnail filename with path and extension
	"tn_width TEXT,".			# Thumbnail width in pixels
	"tn_height TEXT".			# Thumbnail height in pixels

	");") or make_error(S_SQLFAIL);
	$sth->execute() or make_error(S_SQLFAIL);
}

sub init_admin_database()
{
	my ($sth);

	$sth=$dbh->do("DROP TABLE ".SQL_ADMIN_TABLE.";") if(table_exists(SQL_ADMIN_TABLE));
	$sth=$dbh->prepare("CREATE TABLE ".SQL_ADMIN_TABLE." (".

	"num ".get_sql_autoincrement().",".	# Entry number, auto-increments
	"type TEXT,".				# Type of entry (ipban, wordban, etc)
	"comment TEXT,".			# Comment for the entry
	"ival1 INTEGER,".			# Integer value 1 (usually IP)
	"ival2 INTEGER,".			# Integer value 2 (usually netmask)
	"sval1 TEXT".				# String value 1

	");") or make_error(S_SQLFAIL);
	$sth->execute() or make_error(S_SQLFAIL);
}

sub get_sql_autoincrement()
{
	return 'INTEGER PRIMARY KEY NOT NULL AUTO_INCREMENT' if(SQL_DBI_SOURCE=~/^DBI:mysql:/i);
	return 'INTEGER PRIMARY KEY' if(SQL_DBI_SOURCE=~/^DBI:SQLite:/i);

	make_error(S_SQLCONF); # maybe there should be a sane default case instead?
}

sub trim_database()
{
	my ($sth,$row,$order);

	if(TRIM_METHOD==0) { $order='num ASC'; }
	else { $order='lasthit ASC'; }

	if(MAX_POSTS)
	{
		while(count_posts()>MAX_POSTS)
		{
			$sth=$dbh->prepare("SELECT * FROM ".SQL_TABLE." WHERE parent=0 ORDER BY $order LIMIT 1;") or make_error(S_SQLFAIL);
			$sth->execute() or make_error(S_SQLFAIL);

			if($row=$sth->fetchrow_hashref())
			{
				delete_post($$row{num},"",0);
			}
			else { last; } # shouldn't happen
		}
	}

	if(MAX_THREADS)
	{
		my $threads=count_threads();

		while($threads>MAX_THREADS)
		{
			$sth=$dbh->prepare("SELECT * FROM ".SQL_TABLE." WHERE parent=0 ORDER BY $order LIMIT 1;") or make_error(S_SQLFAIL);
			$sth->execute() or make_error(S_SQLFAIL);

			if($row=$sth->fetchrow_hashref())
			{
				delete_post($$row{num},"",0);
			}
			$threads--;
		}
	}

	if(MAX_AGE) # needs testing
	{
		my $mintime=time()-(MAX_AGE)*3600;

		$sth=$dbh->prepare("SELECT * FROM ".SQL_TABLE." WHERE parent=0 AND timestamp<=$mintime;") or make_error(S_SQLFAIL);
		$sth->execute() or make_error(S_SQLFAIL);

		while($row=$sth->fetchrow_hashref())
		{
			delete_post($$row{num},"",0);
		}
	}
}

sub table_exists($)
{
	my ($table)=@_;
	my ($sth);

	return 0 unless($sth=$dbh->prepare("SELECT * FROM ".$table." LIMIT 1;"));
	return 0 unless($sth->execute());
	return 1;
}

sub count_threads()
{
	my ($sth);

	$sth=$dbh->prepare("SELECT count(*) FROM ".SQL_TABLE." WHERE parent=0;") or make_error(S_SQLFAIL);
	$sth->execute() or make_error(S_SQLFAIL);

	return ($sth->fetchrow_array())[0];
}

sub count_posts()
{
	my ($sth);

	$sth=$dbh->prepare("SELECT count(*) FROM ".SQL_TABLE.";") or make_error(S_SQLFAIL);
	$sth->execute() or make_error(S_SQLFAIL);

	return ($sth->fetchrow_array())[0];
}

sub thread_exists($)
{
	my ($thread)=@_;
	my ($sth);

	$sth=$dbh->prepare("SELECT count(*) FROM ".SQL_TABLE." WHERE num=? AND parent=0;") or make_error(S_SQLFAIL);
	$sth->execute($thread) or make_error(S_SQLFAIL);

	return ($sth->fetchrow_array())[0];
}

sub count_replies($)
{
	my ($thread)=@_;
	my ($sth);

	$sth=$dbh->prepare("SELECT count(*) FROM ".SQL_TABLE." WHERE parent=?;") or make_error(S_SQLFAIL);
	$sth->execute($thread) or make_error(S_SQLFAIL);

	return ($sth->fetchrow_array())[0];
}

#sub execute_encoded($@)
#{
#	my ($sth,@args)=@_;
#
#	
#}

sub get_decoded_hashref($)
{
	my ($sth)=@_;
	my ($row);

	$row=$sth->fetchrow_hashref();

	if($row and $has_unicode)
	{
		for my $k (keys %$row) # don't blame me for this shit, I got this from perlunicode.
		{
			defined && /[^\000-\177]/ && Encode::_utf8_on($_) for $row->{$k};
		}

		if(SQL_DBI_SOURCE=~/^DBI:mysql:/i) # OMGWTFBBQ
		{
			for my $k (keys %$row)
			{
				$$row{$k}=~s/chr\(([0-9]+)\)/chr($1)/ge;
			}
		}
	}

	return $row;
}



#
# Image utils
#

sub analyze_image($)
{
	my ($file)=@_;
	my (@res);

	return ("jpg",@res) if(@res=analyze_jpeg($file));
	return ("png",@res) if(@res=analyze_png($file));
	return ("gif",@res) if(@res=analyze_gif($file));

	# find file extension for unknown files
	my ($ext)=$file=~/\.([^\.]+)$/;
	return (lc($ext),0,0);
}

sub analyze_jpeg($)
{
	my ($file)=@_;
	my ($buffer);

	read($file,$buffer,2);

	if($buffer eq "\xff\xd8")
	{
		OUTER:
		for(;;)
		{
			for(;;)
			{
				last OUTER unless(read($file,$buffer,1));
				last if($buffer eq "\xff");
			}

			last unless(read($file,$buffer,3)==3);
			my ($mark,$size)=unpack("Cn",$buffer);
			last if($mark==0xda or $mark==0xd9);  # SOS/EOI
			last if($size<2);

			if($mark>=0xc0 and $mark<=0xc2) # SOF0..SOF2 - what the hell are the rest? 
			{
				last unless(read($file,$buffer,5)==5);
				my ($bits,$height,$width)=unpack("Cnn",$buffer);
				seek($file,0,0);

				return($width,$height);
			}

			seek($file,$size-2,1);
		}
	}

	seek($file,0,0);

	return ();
}

sub analyze_png($)
{
	my ($file)=@_;
	my ($bytes,$buffer);

	$bytes=read($file,$buffer,24);
	seek($file,0,0);
	return () unless($bytes==24);

	my ($magic1,$magic2,$length,$ihdr,$width,$height)=unpack("NNNNNN",$buffer);

	return () unless($magic1==0x89504e47 and $magic2==0x0d0a1a0a and $ihdr==0x49484452);

	return ($width,$height);
}

sub analyze_gif($)
{
	my ($file)=@_;
	my ($bytes,$buffer);

	$bytes=read($file,$buffer,10);
	seek($file,0,0);
	return () unless($bytes==10);

	my ($magic,$width,$height)=unpack("A6 vv",$buffer);

	return () unless($magic eq "GIF87a" or $magic eq "GIF89a");

	return ($width,$height);
}

sub make_thumbnail($$$$)
{
	my ($filename,$thumbnail,$width,$height)=@_;

	if($has_magick)
	{
		my ($res,$magick);

		$filename.="[0]" if($filename=~/\.gif$/);

		$magick=Image::Magick->new;

		$res=$magick->Read($filename);
		return 0 if "$res";
		$res=$magick->Scale(width=>$width, height=>$height);
		return 0 if "$res";
		$res=$magick->Write(filename=>$thumbnail, quality=>THUMBNAIL_QUALITY);
		return 0 if "$res";

		return 1;
	}
#	elsif($has_gd) # not yet implemented
#	{
#	}
	else # use external commands
	{
		# first try ImageMagick

		my $magickname=$filename;
		$magickname.="[0]" if($magickname=~/\.gif$/);

		my $convert=CONVERT_COMMAND;
		my $quality=THUMBNAIL_QUALITY;
		`$convert -size ${width}x$height -geometry ${width}x${height}! -quality $quality $magickname $thumbnail 2>&1`;

		return(1) unless($?);

		# if that fails, try pnmtools instead

		if($filename=~/\.jpg$/)
		{
			`djpeg $filename | pnmscale -width $width -height $height | cjpeg -quality $quality > $thumbnail`;
			# could use -scale 1/n
			return(1) unless($?);
		}
		elsif($filename=~/\.png$/)
		{
			`pngtopnm $filename | pnmscale -width $width -height $height | cjpeg -quality $quality > $thumbnail`;
			return(1) unless($?);
		}
		elsif($filename=~/\.gif$/)
		{
			`giftopnm $filename | pnmscale -width $width -height $height | cjpeg -quality $quality > $thumbnail`;
			return(1) unless($?);
		}
	}

	return(0);
}
