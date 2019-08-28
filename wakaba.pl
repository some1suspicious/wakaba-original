#!/usr/bin/perl

use CGI::Carp qw(fatalsToBrowser);

use strict;

use CGI;
use DBI;


#
# Import settings
#

use lib '.';
BEGIN { require "config.pl"; }
BEGIN { require "config_defaults.pl"; }
BEGIN { require "strings_e.pl"; }		# edit this line to change the language
BEGIN { require "futaba_style.pl"; }	# edit this line to change the board style
BEGIN { require "captcha.pl"; }
BEGIN { require "wakautils.pl"; }



#
# Optional modules
#

my ($has_encode);

if(CONVERT_CHARSETS)
{
	eval 'use Encode qw(decode)';
	$has_encode=1 unless($@);
}



#
# Global init
#

my $query=new CGI;
my $task=($query->param("task") or $query->param("action"));

my $dbh=DBI->connect(SQL_DBI_SOURCE,SQL_USERNAME,SQL_PASSWORD,{AutoCommit=>1}) or make_error(S_SQLCONF);

# check for admin table
init_admin_database() if(!table_exists(SQL_ADMIN_TABLE));

if(!table_exists(SQL_TABLE)) # check for comments table
{
	init_database();
	build_cache();
	make_http_forward(HTML_SELF,ALTERNATE_REDIRECT);
}
elsif(!$task)
{
	make_http_forward(HTML_SELF,ALTERNATE_REDIRECT);
}
elsif($task eq "post")
{
	my $parent=$query->param("parent");
	my $name=$query->param("name");
	my $email=$query->param("email");
	my $subject=$query->param("subject");
	my $comment=$query->param("comment");
	my $file=$query->param("file");
	my $password=$query->param("password");
	my $nofile=$query->param("nofile");
	my $captcha=$query->param("captcha");
	my $admin=$query->param("admin");
	my $fake_ip=$query->param("fake_ip");
	my $no_captcha=$query->param("no_captcha");
	my $no_format=$query->param("no_format");
	my $postfix=$query->param("postfix");

	post_stuff($parent,$name,$email,$subject,$comment,$file,$password,$nofile,$captcha,$admin,$fake_ip,$no_captcha,$no_format,$postfix);
}
elsif($task eq "delete")
{
	my $password=$query->param("password");
	my $fileonly=$query->param("fileonly");
	my $admin=$query->param("admin");
	my @posts=$query->param("delete");

	delete_stuff($password,$fileonly,$admin,@posts);
}
elsif($task eq "admin")
{
	my $password=$query->param("berra"); # lol obfuscation
	my $nexttask=$query->param("nexttask");

	if($password) { do_login($password,$nexttask) }
	else { make_admin_login() }
}
elsif($task eq "mpanel")
{
	my $admin=$query->param("admin");
	make_admin_post_panel($admin);
}
elsif($task eq "deleteall")
{
	my $admin=$query->param("admin");
	my $ip=$query->param("ip");
	my $mask=$query->param("mask");
	delete_all($admin,parse_range($ip,$mask));
}
elsif($task eq "bans")
{
	my $admin=$query->param("admin");
	make_admin_ban_panel($admin);
}
elsif($task eq "addip")
{
	my $admin=$query->param("admin");
	my $type=$query->param("type");
	my $comment=$query->param("comment");
	my $ip=$query->param("ip");
	my $mask=$query->param("mask");
	add_admin_entry($admin,$type,$comment,parse_range($ip,$mask),'');
}
elsif($task eq "addstring")
{
	my $admin=$query->param("admin");
	my $type=$query->param("type");
	my $string=$query->param("string");
	my $comment=$query->param("comment");
	add_admin_entry($admin,$type,$comment,0,0,$string);
}
elsif($task eq "removeban")
{
	my $admin=$query->param("admin");
	my $num=$query->param("num");
	remove_admin_entry($admin,$num);
}
elsif($task eq "spam")
{
	my ($admin);
	$admin=$query->param("admin");
	make_admin_spam_panel($admin);
}
elsif($task eq "updatespam")
{
	my $admin=$query->param("admin");
	my $spam=$query->param("spam");
	update_spam_file($admin,$spam);
}
elsif($task eq "sqldump")
{
	my $admin=$query->param("admin");
	make_sql_dump($admin);
}
elsif($task eq "sql")
{
	my $admin=$query->param("admin");
	my $nuke=$query->param("nuke");
	my $sql=$query->param("sql");
	make_sql_interface($admin,$nuke,$sql);
}
elsif($task eq "mpost")
{
	my $admin=$query->param("admin");
	make_admin_post($admin);
}
elsif($task eq "rebuild")
{
	my $admin=$query->param("admin");
	do_rebuild_cache($admin);
}
elsif($task eq "nuke")
{
	my $admin=$query->param("admin");
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

	# grab all posts, in thread order (ugh, ugly kludge)
	$sth=$dbh->prepare("SELECT * FROM ".SQL_TABLE." ORDER BY lasthit DESC,CASE parent WHEN 0 THEN num ELSE parent END ASC,num ASC") or make_error(S_SQLFAIL);
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
		$PerlIO::encoding::fallback=0x0200 if($has_encode);
		binmode PAGE,':encoding('.CHARSET.')' if($has_encode);
		print_page(\*PAGE,$page,$total,@threads);
		close PAGE;

		make_error(S_NOTWRITE) unless(rename $tmpname,$filename);
	}
	else
	{
		open (PAGE,">$filename") or make_error(S_NOTWRITE);
		$PerlIO::encoding::fallback=0x0200 if($has_encode);
		binmode PAGE,':encoding('.CHARSET.')' if($has_encode);
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
		$PerlIO::encoding::fallback=0x0200 if($has_encode);
		binmode PAGE,':encoding('.CHARSET.')' if($has_encode);
		print_reply(\*PAGE,@thread);
		close PAGE;

		rename $tmpname,$filename;
	}
	else
	{
		open (PAGE,">$filename") or make_error(S_NOTWRITE);
		$PerlIO::encoding::fallback=0x0200 if($has_encode);
		binmode PAGE,':encoding('.CHARSET.')' if($has_encode);
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

sub post_stuff($$$$$$$$$$$$$$$)
{
	my ($parent,$name,$email,$subject,$comment,$file,$password,$nofile,$captcha,$admin,$fake_ip,$no_captcha,$no_format,$postfix)=@_;

	# get a timestamp for future use
	my $time=time();

	# check that the request came in as a POST, or from the command line
	make_error(S_UNJUST) if($ENV{REQUEST_METHOD} and $ENV{REQUEST_METHOD} ne "POST");

	if($admin) # check admin password
	{
		check_password($admin,ADMIN_PASS);
	}
	else # forbid admin-only features
	{
		make_error(S_WRONGPASS) if($fake_ip or $no_captcha or $no_format or $postfix);
	}

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
	my $size=get_file_size($file) if($file);

	# find hostname
	my $ip=($fake_ip or $ENV{REMOTE_ADDR});

	#$host = gethostbyaddr($ip);
	my $numip=dot_to_dec($ip);

	# check if IP is whitelisted
	my $whitelisted=is_whitelisted($numip);

	# check captcha - should whitelists affect captcha?
	check_captcha($dbh,$captcha,$ip,$parent) if(ENABLE_CAPTCHA and !$no_captcha);

	# check for bans
	ban_check($numip,$name,$subject,$comment) unless($whitelisted);

	# spam check
	make_error(S_SPAM) if(spam_check($comment,SPAM_FILE));
	make_error(S_SPAM) if(spam_check($subject,SPAM_FILE));
	make_error(S_SPAM) if(spam_check($name,SPAM_FILE));

	# proxy check
	proxy_check($ip) unless($whitelisted);

	# check if thread exists, and get lasthit value
	my ($parent_res,$lasthit);
	if($parent)
	{
		$parent_res=get_parent_post($parent) or make_error(S_NOTHREADERR);
		$lasthit=$$parent_res{lasthit};
	}
	else
	{
		$lasthit=$time;
	}

	# set up cookies
	my $c_name=$name;
	my $c_email=$email;
	my $c_password=$password;

	# clean up the inputs
	$name=clean_string(decode_string($name));
	$email=clean_string(decode_string($email));
	$subject=clean_string(decode_string($subject));

	# process the tripcode
	my $trip;
	($name,$trip)=process_tripcode($name,TRIPKEY,SECRET);

	# format comment
	$comment=decode_string($comment);
	unless($no_format)
	{
		$comment=clean_string($comment);
		$comment=format_comment($comment,$admin);
	}
	$comment.=$postfix;

	# insert default values for empty fields
	$parent=0 unless($parent);
	$name=S_ANONAME unless($name or $trip);
	$subject=S_ANOTITLE unless($subject);
	$comment=S_ANOTEXT unless($comment);

	# flood protection - must happen after inputs have been cleaned up
	flood_check($numip,$time,$comment,$file);

	# Manager and deletion stuff - duuuuuh?

	# generate date
	my $date=make_date($time,DATE_STYLE);

	# generate ID code if enabled
	$date.=' ID:'.make_id_code($ip,$time,$email) if(DISPLAY_ID);

	# copy file, do checksums, make thumbnail, etc
	my ($filename,$md5,$width,$height,$thumbnail,$tn_width,$tn_height)=process_file($file,$time) if($file);

	# finally, write to the database
	my $sth=$dbh->prepare("INSERT INTO ".SQL_TABLE." VALUES(null,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);") or make_error(S_SQLFAIL);
	$sth->execute($parent,$time,$lasthit,$numip,
	$date,$name,$trip,$email,$subject,$password,$comment,
	$filename,$size,$md5,$width,$height,$thumbnail,$tn_width,$tn_height) or make_error(S_SQLFAIL);

	if($parent) # bumping
	{
		# check for sage, or too many replies
		unless($email=~/sage/i or sage_count($parent_res)>MAX_RES)
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
	make_cookies(name=>$c_name,email=>$c_email,password=>$c_password,
	-charset=>CHARSET,-autopath=>COOKIE_PATH); # yum!

	# forward back to the main page
	make_http_forward(HTML_SELF,ALTERNATE_REDIRECT);
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

# fucking mysql...
#	$sth=$dbh->prepare("SELECT count(*) FROM ".SQL_ADMIN_TABLE." WHERE type='wordban' AND ? LIKE '%' || sval1 || '%';") or make_error(S_SQLFAIL);
#	$sth->execute($comment) or make_error(S_SQLFAIL);
#
#	make_error(S_STRREF) if(($sth->fetchrow_array())[0]);

	$sth=$dbh->prepare("SELECT sval1 FROM ".SQL_ADMIN_TABLE." WHERE type='wordban';") or make_error(S_SQLFAIL);
	$sth->execute() or make_error(S_SQLFAIL);

	my $row;
	while($row=$sth->fetchrow_arrayref())
	{
		my $regexp=quotemeta $$row[0];
		make_error(S_STRREF) if($comment=~/$regexp/);
		make_error(S_STRREF) if($name=~/$regexp/);
		make_error(S_STRREF) if($subject=~/$regexp/);
	}

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

sub decode_string($)
{
	my ($str)=@_;

	if($has_encode)
	{
		$str=decode(CHARSET,$str);
		$str=~s/&\#([0-9]+);/chr($1)/ge;
	}

	return $str;
}

sub format_comment($$)
{
	my ($comment,$thread)=@_;

	# fix newlines
	$comment=~s/\r\n/\n/g;
	$comment=~s/\r/\n/g;

	# hide >>1 references from the quoting code
	$comment=~s/&gt;&gt;([0-9\-]+)/&gtgt;$1/g;

	my $handler=sub # fix up >>1 references
	{
		my $line=shift;

		$line=~s!&gtgt;([0-9]+)!
			my $res=get_post($1);
			if($res) { '<a href="'.get_reply_link($$res{num},$$res{parent}).'">&gt;&gt;'.$1.'</a>' }
			else { "&gt;&gt;$1"; }
		!ge;

		return $line;
	};

	my @lines=split /\n/,$comment;
	if(ENABLE_WAKABAMARK) { $comment=do_wakabamark($handler,0,@lines) }
	else { $comment="<p>".simple_format($handler,@lines)."</p>" }

	# restore >>1 references hidden in code blocks
	$comment=~s/&gtgt;/&gt;&gt;/g;

	return $comment;
}

sub simple_format($@)
{
	my $handler=shift;
	return join "<br />",map
	{
		my $line=$_;

		# make URLs into links
		$line=~s{(https?://[^\s<>"]*?)((?:\s|<|>|"|\.|\)|\]|!|\?|,|&#44;|&quot;)*(?:[\s<>"]|$))}{\<a href="$1"\>$1\</a\>$2}sgi;

		# colour quoted sections if working in old-style mode.
		$line=~s!^(&gt;.*)$!\<span class="unkfunc"\>$1\</span\>!g unless(ENABLE_WAKABAMARK);

		$line=$handler->($line) if($handler);

		$line;
	} @_;
}

sub make_id_code($$$)
{
	my ($ip,$time,$email)=@_;

	return EMAIL_ID if($email and DISPLAY_ID==1);

	my $day=int(($time+9*60*60)/86400); # weird time offset copied from futaba
	return encode_base64(rc4(null_string(6),"i".$ip.$day.SECRET),"");
}

sub get_post($)
{
	my ($thread)=@_;
	my ($sth);

	$sth=$dbh->prepare("SELECT * FROM ".SQL_TABLE." WHERE num=?;") or make_error(S_SQLFAIL);
	$sth->execute($thread) or make_error(S_SQLFAIL);

	return $sth->fetchrow_hashref();
}

sub get_parent_post($)
{
	my ($thread)=@_;
	my ($sth);

	$sth=$dbh->prepare("SELECT * FROM ".SQL_TABLE." WHERE num=? AND parent=0;") or make_error(S_SQLFAIL);
	$sth->execute($thread) or make_error(S_SQLFAIL);

	return $sth->fetchrow_hashref();
}

sub sage_count($)
{
	my ($parent)=@_;
	my ($sth);

	$sth=$dbh->prepare("SELECT count(*) FROM ".SQL_TABLE." WHERE parent=? AND NOT ( timestamp<? AND ip=? );") or make_error(S_SQLFAIL);
	$sth->execute($$parent{num},$$parent{timestamp}+(NOSAGE_WINDOW),$$parent{ip}) or make_error(S_SQLFAIL);

	return ($sth->fetchrow_array())[0];
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
	my %filetypes=FILETYPES;

	# make sure to read file in binary mode on platforms that care about such things
	binmode $file;

	# analyze file and check that it's in a supported format
	my ($ext,$width,$height)=analyze_image($file);

	my $known=$width or $filetypes{$ext};

	make_error(S_BADFORMAT) unless(ALLOW_UNKNOWN or $known);
	make_error(S_BADFORMAT) if(grep { $_ eq $ext } FORBIDDEN_EXTENSIONS);
	make_error(S_TOOBIG) if(MAX_IMAGE_WIDTH and $width>MAX_IMAGE_WIDTH);
	make_error(S_TOOBIG) if(MAX_IMAGE_HEIGHT and $height>MAX_IMAGE_HEIGHT);
	make_error(S_TOOBIG) if(MAX_IMAGE_PIXELS and $width*$height>MAX_IMAGE_PIXELS);

	# generate random filename - fudges the microseconds
	my $filebase=$time.sprintf("%03d",int(rand(1000)));
	my $filename=IMG_DIR.$filebase.'.'.$ext;
	my $thumbnail=THUMB_DIR.$filebase."s.jpg";
	$filename.=MUNGE_UNKNOWN unless($known);

	# do copying and MD5 checksum
	my ($md5,$md5ctx,$buffer);

	# prepare MD5 checksum if the Digest::MD5 module is available
	eval 'use Digest::MD5 qw(md5_hex)';
	$md5ctx=Digest::MD5->new unless($@);

	# copy file
	open (OUTFILE,">>$filename") or make_error(S_NOTWRITE);
	binmode OUTFILE;
	while (read($file,$buffer,1024)) # should the buffer be larger?
	{
		print OUTFILE $buffer;
		$md5ctx->add($buffer) if($md5ctx);
	}
	close $file;
	close OUTFILE;

	if($md5ctx) # if we have Digest::MD5, get the checksum
	{
		$md5=$md5ctx->hexdigest();
	}
	else # otherwise, try using the md5sum command
	{
		my $md5sum=`md5sum $filename`; # filename is always the timestamp name, and thus safe
		($md5)=$md5sum=~/^([0-9a-f]+)/ unless($?);
	}

	if($md5) # if we managed to generate an md5 checksum, check for duplicate files
	{
		my $sth=$dbh->prepare("SELECT * FROM ".SQL_TABLE." WHERE md5=?;") or make_error(S_SQLFAIL);
		$sth->execute($md5) or make_error(S_SQLFAIL);

		if(my $match=$sth->fetchrow_hashref())
		{
			unlink $filename; # make sure to remove the file
			make_error(sprintf(S_DUPE,get_reply_link($$match{num},$$match{parent})));
		}
	}

	# do thumbnail
	my ($tn_width,$tn_height,$tn_ext);

	if(!$width) # unsupported file
	{
		if($filetypes{$ext}) # externally defined filetype
		{
			open THUMBNAIL,$filetypes{$ext};
			binmode THUMBNAIL;
			($tn_ext,$tn_width,$tn_height)=analyze_image(\*THUMBNAIL);
			close THUMBNAIL;

			# was that icon file really there?
			if(!$tn_width) { $thumbnail=undef }
			else { $thumbnail=$filetypes{$ext} }
		}
		else
		{
			$thumbnail=undef;
		}
	}
	elsif($width>MAX_W or $height>MAX_H or THUMBNAIL_SMALL)
	{
		if($width<=MAX_W and $height<=MAX_H)
		{
			$tn_width=$width;
			$tn_height=$height;
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
		}

		if(STUPID_THUMBNAILING) { $thumbnail=$filename }
		else
		{
			$thumbnail=undef unless(make_thumbnail($filename,$thumbnail,$tn_width,$tn_height,THUMBNAIL_QUALITY,CONVERT_COMMAND));
		}
	}
	else
	{
		$tn_width=$width;
		$tn_height=$height;
		$thumbnail=$filename;
	}

	if($filetypes{$ext}) # externally defined filetype - restore the name
	{
		my $newfilename=$file;
		$newfilename=~s!^.*[\\/]!!; # cut off any directory in filename
		$newfilename=IMG_DIR.$newfilename;

		unless(-e $newfilename) # verify no name clash
		{
			rename $filename,$newfilename;
			$filename=$newfilename;
		}
		else
		{
			unlink $filename;
			make_error(S_DUPENAME);
		}
	}

	return ($filename,$md5,$width,$height,$thumbnail,$tn_width,$tn_height);
}



#
# Deleting
#

sub delete_stuff($$$@)
{
	my ($password,$fileonly,$admin,@posts)=@_;
	my ($post);

	check_password($admin,ADMIN_PASS) if($admin);
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
	{ make_http_forward($ENV{SCRIPT_NAME}."?admin=$admin&task=mpanel",ALTERNATE_REDIRECT); }
	else
	{ make_http_forward(HTML_SELF,ALTERNATE_REDIRECT); }
}

sub delete_post($$$)
{
	my ($post,$password,$fileonly)=@_;
	my ($sth,$row,$res,$reply);
	my $thumb=THUMB_DIR;

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
				# delete images if they exist
				unlink $$res{image};
				unlink $$row{thumbnail} if($$row{thumbnail}=~/^$thumb/);
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
				unlink $$row{thumbnail} if($$row{thumbnail}=~/^$thumb/);

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

	check_password($admin,ADMIN_PASS);

	$sth=$dbh->prepare("SELECT * FROM ".SQL_TABLE." ORDER BY lasthit DESC,CASE parent WHEN 0 THEN num ELSE parent END ASC,num ASC;") or make_error(S_SQLFAIL);
	$sth->execute() or make_error(S_SQLFAIL);
	while($row=get_decoded_hashref($sth)) { push @posts,$row }

	make_http_header();
	print_admin_post_panel(\*STDOUT,$admin,@posts);
}

sub make_admin_ban_panel($)
{
	my ($admin)=@_;
	my ($sth,$row,@bans);

	check_password($admin,ADMIN_PASS);

	$sth=$dbh->prepare("SELECT * FROM ".SQL_ADMIN_TABLE." WHERE type='ipban' OR type='wordban' OR type='whitelist' ORDER BY type ASC,num ASC;") or make_error(S_SQLFAIL);
	$sth->execute() or make_error(S_SQLFAIL);
	while($row=get_decoded_hashref($sth)) { push @bans,$row }

	make_http_header();
	print_admin_ban_panel(\*STDOUT,$admin,@bans);
}

sub make_admin_spam_panel($)
{
	my ($admin)=@_;

	check_password($admin,ADMIN_PASS);

	make_http_header();
	print_admin_spam_panel(\*STDOUT,$admin,read_array(SPAM_FILE));
}

sub make_sql_dump($)
{
	my ($admin)=@_;
	my ($sth,$row,@database);

	check_password($admin,ADMIN_PASS);

	$sth=$dbh->prepare("SELECT * FROM ".SQL_TABLE.";") or make_error(S_SQLFAIL);
	$sth->execute() or make_error(S_SQLFAIL);
	while($row=get_decoded_arrayref($sth))
	{
		push @database,clean_string("INSERT INTO ".SQL_TABLE." VALUES('".
		(join "','",map { s/([\\'])/\\$1/g; $_ } @{$row}). # escape ' and \, and join up all values with commas and apostrophes
		"');");
	}

	make_http_header();
	print_admin_sql_dump(\*STDOUT,$admin,@database);
}

sub make_sql_interface($$$)
{
	my ($admin,$nuke,$sql)=@_;
	my ($sth,$row,@results);

	check_password($admin,ADMIN_PASS);

	if($sql)
	{
		make_error(S_WRONGPASS) if($nuke ne NUKE_PASS); # check nuke password

		my @statements=grep { /^\S/ } split /\r?\n/,decode_string($sql);

		foreach my $statement (@statements)
		{
			push @results,">>> $statement";
			if($sth=$dbh->prepare($statement))
			{
				if($sth->execute())
				{
					while($row=get_decoded_arrayref($sth)) { push @results,clean_string(join ' | ',@{$row}) }
				}
				else { push @results,"!!! ".$sth->errstr() }
			}
			else { push @results,"!!! ".$sth->errstr() }
		}
	}

	make_http_header();
	print_admin_sql_interface(\*STDOUT,$admin,$nuke,@results);
}

sub do_login($$)
{
	my ($password,$nexttask)=@_;
	my $crypt=crypt_password($password);

	make_http_forward(get_script_name()."?task=$nexttask&admin=$crypt",ALTERNATE_REDIRECT)
}

sub make_admin_post($)
{
	my ($admin)=@_;

	check_password($admin,ADMIN_PASS);

	make_http_header();
	print_admin_post(\*STDOUT,$admin);
}

sub do_rebuild_cache($)
{
	my ($admin)=@_;

	check_password($admin,ADMIN_PASS);

	unlink glob RES_DIR.'*';

	repair_database();
	build_thread_cache_all();
	build_cache();

	make_http_forward(HTML_SELF,ALTERNATE_REDIRECT);
}

sub add_admin_entry($$$$$$)
{
	my ($admin,$type,$comment,$ival1,$ival2,$sval1)=@_;
	my ($sth);

	check_password($admin,ADMIN_PASS);

	$comment=clean_string($comment);

	$sth=$dbh->prepare("INSERT INTO ".SQL_ADMIN_TABLE." VALUES(null,?,?,?,?,?);") or make_error(S_SQLFAIL);
	$sth->execute($type,$comment,$ival1,$ival2,$sval1) or make_error(S_SQLFAIL);

	make_http_forward(get_script_name()."?admin=$admin&task=bans",ALTERNATE_REDIRECT);
}

sub remove_admin_entry($$)
{
	my ($admin,$num)=@_;
	my ($sth);

	check_password($admin,ADMIN_PASS);

	$sth=$dbh->prepare("DELETE FROM ".SQL_ADMIN_TABLE." WHERE num=?;") or make_error(S_SQLFAIL);
	$sth->execute($num) or make_error(S_SQLFAIL);

	make_http_forward(get_script_name()."?admin=$admin&task=bans",ALTERNATE_REDIRECT);
}

sub delete_all($$$)
{
	my ($admin,$ip,$mask)=@_;
	my ($sth,$row,@posts);

	check_password($admin,ADMIN_PASS);

	$sth=$dbh->prepare("SELECT num FROM ".SQL_TABLE." WHERE ip & ? = ?;") or make_error(S_SQLFAIL);
	$sth->execute($mask,$ip&$mask) or make_error(S_SQLFAIL);
	while($row=$sth->fetchrow_hashref()) { push(@posts,$$row{num}); }

	delete_stuff('',0,$admin,@posts);
}

sub update_spam_file($$)
{
	my ($admin,$spam)=@_;

	check_password($admin,ADMIN_PASS);

	my @spam=split /\r?\n/,$spam;
	make_error(S_NOTWRITE) unless(write_array(SPAM_FILE,@spam));

	make_http_forward(get_script_name()."?admin=$admin&task=spam",ALTERNATE_REDIRECT);
}

sub do_nuke_database($)
{
	my ($admin)=@_;

	check_password($admin,NUKE_PASS);

	init_database();

	# remove images, thumbnails and threads
	unlink glob IMG_DIR.'*';
	unlink glob THUMB_DIR.'*';
	unlink glob RES_DIR.'*';

	build_cache();

	make_http_forward(HTML_SELF,ALTERNATE_REDIRECT);
}

sub check_password($$)
{
	my ($admin,$password)=@_;
	my $crypt=crypt_password($password);

	make_error(S_WRONGPASS) if($admin ne $crypt);
}

sub crypt_password($)
{
	my $crypt=encode_base64(rc4(null_string(9),"a".(shift).$ENV{REMOTE_ADDR}.SECRET),"");
	$crypt=~tr/+/./; # for web shit
	return $crypt;
}



#
# Page creation utils
#

sub make_http_header()
{
	print "Content-Type: text/html";
	print "; charset=".CHARSET if(CHARSET);
	print "\n";
	print "\n";

	$PerlIO::encoding::fallback=0x0200;
	binmode STDOUT,':encoding('.CHARSET.')'  if($has_encode);
}

sub make_error($)
{
	my ($error)=@_;

	print "Status: 500 $error\n";
	print "Content-Type: text/html";
	print "; charset=".CHARSET if(CHARSET);
	print "\n";
	print "\n";

	print_error(\*STDOUT,$error);

	if($dbh)
	{
		$dbh->{Warn}=0;
		$dbh->disconnect();
	}

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

sub get_script_name()
{
	return $ENV{SCRIPT_NAME};
}

sub get_secure_script_name()
{
	return 'https://'.$ENV{SERVER_NAME}.$ENV{SCRIPT_NAME} if(USE_SECURE_ADMIN);
	return $ENV{SCRIPT_NAME};
}

sub get_reply_link($$)
{
	my ($reply,$parent)=@_;

	return expand_filename(RES_DIR.$parent.PAGE_EXT).'#'.$reply if($parent);
	return expand_filename(RES_DIR.$reply.PAGE_EXT);
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

sub get_stylesheets()
{
	my $found=0;
	my @stylesheets=map
	{
		my %sheet;

		$sheet{filename}=$_;

		($sheet{title})=m!([^/]+)\.css$!i;
		$sheet{title}=ucfirst $sheet{title};
		$sheet{title}=~s/_/ /g;
		$sheet{title}=~s/ ([a-z])/ \u$1/g;
		$sheet{title}=~s/([a-z])([A-Z])/$1 $2/g;

		if($sheet{title} eq DEFAULT_STYLE) { $sheet{default}=1; $found=1; }
		else { $sheet{default}=0; }

		\%sheet;
	} glob(CSS_DIR."*.css");

	$stylesheets[0]{default}=1 if(@stylesheets and !$found);

	return @stylesheets;
}

sub expand_filename($)
{
	my ($filename)=@_;
	return $filename if($filename=~m!^/!);
	return $filename if($filename=~m!^\w+:!);

	my ($self_path)=$ENV{SCRIPT_NAME}=~m!^(.*/)[^/]+$!;
	return $self_path.$filename;
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

	$ip=dot_to_dec($ip) if($ip=~/^\d+\.\d+\.\d+\.\d+$/);

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
	"ip TEXT,".				# IP number of poster, in integer form!

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
	"ival1 TEXT,".			# Integer value 1 (usually IP)
	"ival2 TEXT,".			# Integer value 2 (usually netmask)
	"sval1 TEXT".				# String value 1

	");") or make_error(S_SQLFAIL);
	$sth->execute() or make_error(S_SQLFAIL);
}

sub repair_database()
{
	my ($sth,$row,@threads,$thread);

	$sth=$dbh->prepare("SELECT * FROM ".SQL_TABLE." WHERE parent=0;") or make_error(S_SQLFAIL);
	$sth->execute() or make_error(S_SQLFAIL);

	while($row=$sth->fetchrow_hashref()) { push(@threads,$row); }

	foreach $thread (@threads)
	{
		# fix lasthit
		my ($upd);

		$upd=$dbh->prepare("UPDATE ".SQL_TABLE." SET lasthit=? WHERE parent=?;") or make_error(S_SQLFAIL);
		$upd->execute($$row{lasthit},$$row{num}) or make_error(S_SQLFAIL." ".$dbh->errstr());
	}
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

sub get_decoded_hashref($)
{
	my ($sth)=@_;

	my $row=$sth->fetchrow_hashref();

	if($row and $has_encode)
	{
		for my $k (keys %$row) # don't blame me for this shit, I got this from perlunicode.
		{ defined && /[^\000-\177]/ && Encode::_utf8_on($_) for $row->{$k}; }

		if(SQL_DBI_SOURCE=~/^DBI:mysql:/i) # OMGWTFBBQ
		{ for my $k (keys %$row) { $$row{$k}=~s/chr\(([0-9]+)\)/chr($1)/ge; } }
	}

	return $row;
}

sub get_decoded_arrayref($)
{
	my ($sth)=@_;

	my $row=$sth->fetchrow_arrayref();

	if($row and $has_encode)
	{
		# don't blame me for this shit, I got this from perlunicode.
		defined && /[^\000-\177]/ && Encode::_utf8_on($_) for @$row;

		if(SQL_DBI_SOURCE=~/^DBI:mysql:/i) # OMGWTFBBQ
		{ s/chr\(([0-9]+)\)/chr($1)/ge for @$row; }
	}

	return $row;
}
