#!/usr/bin/perl

use CGI::Carp qw(fatalsToBrowser);

use strict;

use CGI;
use MIME::Base64;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use Encode qw(decode);

use lib '.';
BEGIN { require 'config.pl'; }
BEGIN { require 'templates.pl'; }



#
# Global init
#

my ($query,$action);

$query=new CGI;
$action=$query->param("action");

if(!$action)
{
	build_all_main_pages() unless(-e HTML_SELF);

	make_http_forward(HTML_SELF);
}
elsif($action eq "post")
{
	my ($parent,$name,$email,$subject,$comment,$file,$password,$nofile,$captcha,$key);

	$parent=$query->param("parent");
	$name=$query->param("name");
	$email=$query->param("email");
	$subject=$query->param("subject");
	$comment=$query->param("comment");
	$file=$query->param("file");
	$password=$query->param("password");
	$nofile=$query->param("nofile");
	$captcha=$query->param("captcha");
	$key=$query->param("key");

	post_stuff($parent,$name,$email,$subject,$comment,$file,$password,$nofile,$captcha,$key);
}
elsif($action eq "delete")
{
	my ($password,$fileonly,@posts);

	$password=$query->param("password");
	$fileonly=$query->param("fileonly");
	@posts=$query->param("delete");

	delete_stuff($password,$fileonly,@posts);
}




sub build_all_main_pages()
{
	my @pages=get_pages(1);
	my $num=0;
	my $total=int((@pages+THREADS_PER_PAGE-1)/THREADS_PER_PAGE);

	if(@pages)
	{
		while(@pages)
		{
			my @thispage;
			for(my $i=0;$i<THREADS_PER_PAGE and @pages;$i++) { push @thispage,shift @pages; }
#			(@thispage[0..THREADS_PER_PAGE-1],@pages)=@pages;
#			while(!$thispage[$#thispage]) { pop @thispage; }

			build_main_page(($num?$num.PAGE_EXT:HTML_SELF),$num,$total,@thispage);

			$num++;
		}
	}
	else
	{
		build_main_page(HTML_SELF,0,1);
		$num=1;
	}

	while(-e $num.PAGE_EXT)
	{
		unlink $num.PAGE_EXT;
		$num++;
	}
}

sub build_main_page($$$@)
{
	my ($filename,$num,$total,@pages)=@_;
	my @mainpage;
	my %linkvars;

	if($num==1) { $linkvars{prev}=HTML_SELF; }
	elsif($num>1) { $linkvars{prev}=($num-1).PAGE_EXT; }
	else { $linkvars{prev}=''; }

	if($num!=$total-1) { $linkvars{next}=($num+1).PAGE_EXT; }
	else { $linkvars{next}=''; }

	$linkvars{pages}=[map { { page=>$_,link=>$_.PAGE_EXT,curr=>$_==$num } } (0..$total-1)];
	$linkvars{pages}[0]{link}=HTML_SELF;

	push @mainpage,make_template(HEAD_TEMPLATE,%linkvars,thread=>0,num=>$num,total=>$total);

	foreach my $page (@pages)
	{
		my @replypage=read_array($page);
		my $replies=@replypage-3;
		my $omit=$replies-(REPLIES_PER_THREAD);
		my $images=0;

		$omit=0 if($omit<0);

		foreach(splice @replypage,2,$omit) { $images++ if( get_images($_)); }
		my @replies=map { {reply=>$_} } splice @replypage,2,-1;

		push @mainpage,make_template(SUMMARY_TEMPLATE,
		page=>$page,omit=>$omit,images=>$images,threadstart=>$replypage[1],
		replies=>\@replies);
	}

	push @mainpage,make_template(FOOT_TEMPLATE,%linkvars,thread=>0,num=>$num,total=>$total);

	write_array($filename,@mainpage);
}

sub build_reply(%)
{
	my (%vars)=@_;
	my @page;

	if($vars{parent})
	{
		my $filename=RES_DIR.$vars{parent}.PAGE_EXT;
		@page=read_array($filename);

		my $posts=@page-2;
		my $footer=pop @page;
		my $num=get_post_num($page[$#page])+1;

		push @page,make_template(REPLY_TEMPLATE,%vars,num=>$num);
		push @page,$footer;

		write_array($filename,@page);

		# check for sage, or too many replies
		add_bump($vars{parent}) unless($vars{email}=~/sage/i or $posts>=MAX_RES);
		add_log($vars{parent},$num,$vars{password},$vars{ip});
	}
	else
	{
		my @pages=glob(RES_DIR."*".PAGE_EXT);
		my $thread;

		map { m!([0-9]+)[^/]*$!; $thread=$1 if($1>$thread); } @pages;
		$thread++;

		push @page,make_template(HEAD_TEMPLATE,thread=>$thread);
		push @page,make_template(THREAD_TEMPLATE,%vars,thread=>$thread);
		push @page,make_template(FOOT_TEMPLATE,thread=>$thread);

		write_array(RES_DIR.$thread.PAGE_EXT,@page);

		add_bump($thread);
		add_log($thread,1,$vars{password},$vars{ip});
	}
}



#
# Posting
#

sub post_stuff($$$$$$$$$$$)
{
	my ($parent,$name,$email,$subject,$comment,$file,$password,$nofile,$captcha,$key)=@_;
	my ($sth,$row,$ip,$host,$whitelisted,$trip,$time,$date,);
	my ($image,$size,$width,$height,$thumbnail,$tn_width,$tn_height);

	# get a timestamp for future use
	$time=time();

	# check that the request came in as a POST, or from the command line
	die S_UNJUST if($ENV{REQUEST_METHOD} and $ENV{REQUEST_METHOD} ne "POST");

	# check for weird characters
	die S_UNUSUAL if($parent=~/[^0-9]/);
	die S_UNUSUAL if(length($parent)>10);
	die S_UNUSUAL if($name=~/[\n\r]/);
	die S_UNUSUAL if($email=~/[\n\r]/);
	die S_UNUSUAL if($subject=~/[\n\r]/);

	# check for excessive amounts of text
	die S_TOOLONG if(length($name)>MAX_FIELD_LENGTH);
	die S_TOOLONG if(length($email)>MAX_FIELD_LENGTH);
	die S_TOOLONG if(length($subject)>MAX_FIELD_LENGTH);
	die S_TOOLONG if(length($comment)>MAX_COMMENT_LENGTH);

	# check to make sure the user selected a file, or clicked the checkbox
	die S_NOPIC if(!$parent and !$file and !$nofile);

	# check for empty reply or empty text-only post
	die S_NOTEXT if($comment=~/^\s*$/ and !$file);

	# get file size, and check for limitations.
	$size=get_file_size($file) if($file);

	# find hostname
	$ip=$ENV{REMOTE_ADDR};
	#$host = gethostbyaddr($ip);

	# check captcha
	if(ENABLE_CAPTCHA)
	{
		die S_BADCAPTCHA if(lc($captcha) ne make_word($key));
		die S_BADCAPTCHA if(add_key($key));
	}

	# proxy check
#	proxy_check($ip) unless($whitelisted);

	# check if thread exists
	die S_NOTHREADERR if($parent and !-e RES_DIR.$parent.PAGE_EXT);

	# remember cookies
	my $c_name=$name;
	my $c_email=$email;
	my $c_password=$password;

	# process the tripcode
	($name,$trip)=process_tripcode($name);

	# clean up the inputs
	$name=clean_string($name);
	$email=clean_string($email);
	$subject=clean_string($subject);
	$comment=clean_string($comment);

	# format comment
	$comment=format_comment($comment);

	# insert default values for empty fields
	$parent=0 unless($parent);
	$name=S_ANONAME unless($name||$trip);
	$subject=S_ANOTITLE unless($subject);
	$comment=S_ANOTEXT unless($comment);

	# flood protection - must happen after inputs have been cleaned up
#	flood_check($numip,$time,$comment,$file);

	# Manager and deletion stuff - duuuuuh?

	# generate date
	$date=make_date($time,DATE_STYLE);

	# generate ID code if enabled
	$date.=' ID:'.make_id_code($ip,$time,$email) if(DISPLAY_ID);

	# copy file, do checksums, make thumbnail, etc
	($image,$width,$height,$thumbnail,$tn_width,$tn_height)=process_file($file,$time) if($file);

	build_reply(ip=>$ip,parent=>$parent,subject=>$subject,name=>$name,trip=>$trip,
	email=>$email,date=>$date,comment=>$comment,password=>$password,image=>$image,
	width=>$width,height=>$height,size=>$size,thumbnail=>$thumbnail,
	tn_width=>$tn_width,tn_height=>$tn_height);

	# remove old threads from the database
	trim_pages();

	build_all_main_pages();

	# set the name, email and password cookies
	make_cookies(name=>$c_name,email=>$c_email,password=>$c_password); # yum!

	# forward back to the main page
	make_http_forward(HTML_SELF);
}

sub make_word($)
{
	my ($key)=@_;
	my %grammar=(
		W => ["%C%%T%","%C%%T%","%C%%X%","%C%%D%%F%","%C%%V%%F%%T%","%C%%D%%F%%U%","%C%%T%%U%","%I%%T%","%I%%C%%T%","%A%"],
		A => ["%K%%V%%K%%V%tion"],
		K => ["b","c","d","f","g","j","l","m","n","p","qu","r","s","t","v","s%P%"],
		I => ["ex","in","un","re","de"],
		T => ["%V%%F%","%V%%E%e"],
		U => ["er","ish","ly","en","ing","ness","ment","able","ive"],
		C => ["b","c","ch","d","f","g","h","j","k","l","m","n","p","qu","r","s","sh","t","th","v","w","y","s%P%","%R%r","%L%l"],
		E => ["b","c","ch","d","f","g","dg","l","m","n","p","r","s","t","th","v","z"],
		F => ["b","tch","d","ff","g","gh","ck","ll","m","n","n","ng","p","r","ss","sh","t","tt","th","x","y","zz","r%R%","s%P%","l%L%"],
		P => ["p","t","k","c"],
		Q => ["b","d","g"],
		L => ["b","f","k","p","s"],
		R => ["%P%","%Q%","f","th","sh"],
		V => ["a","e","i","o","u"],
		D => ["aw","ei","ow","ou","ie","ea","ai","oy"],
		X => ["e","i","o","aw","ow","oy"]
	);

	srand unpack "N",md5(SECRET.$key);

	return cfg_expand("%W%",%grammar);
}

sub cfg_expand($%)
{
	my ($str,%grammar)=@_;
	$str=~s/%(\w+)%/
		my @expansions=@{$grammar{$1}};
		cfg_expand($expansions[rand @expansions],%grammar);
	/ge;
	return $str;
}

sub proxy_check($)
{
	my ($ip)=@_;

	for my $port (PROXY_CHECK)
	{
		# needs to be implemented
		# die sprintf S_PROXY,$port);
	}
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

sub clean_string($)
{
	my ($str)=@_;

	$str=~s/^\s*//; # remove preceeding whitespace
	$str=~s/\s*$//; # remove traling whitespace

	$str=~s/&/&amp;/g;
	$str=~s/\</&lt;/g;
	$str=~s/\>/&gt;/g;
	$str=~s/"/&quot;/g; #"
	$str=~s/'/&#039;/g;
	$str=~s/,/&#44;/g;

	# repair unicode entities
	$str=~s/&amp;(\#[0-9]+;)/&$1/g;

	return $str;
}

sub format_comment($)
{
	my ($comment)=@_;
	# fix newlines
	$comment=~s/\r\n/\n/g;
	$comment=~s/\r/\n/g;

	# colour quoted sections
	$comment=~s!^(&gt;.*)$!\<span class="unkfunc"\>$1\</span\>!gm;

	# make URLs into links - is this magic or what
	$comment=~s!(http://[^\s\<\>"]*[^\s\<\>"\.\)\],])!\<a href="$1"\>$1\</a\>!sgi;

	# count number of newlines if MAX_LINES is not 0 - wow, magic. also, admin posts can be longer.
	if(MAX_LINES and scalar(()=$comment=~m/\n/g)>=MAX_LINES)
	{
		$comment=~s/\n/ /g; # remove newlines
	}
	else
	{
		$comment=~s!\n!\<br /\>!g; # replace newlines with <br />
	}

	return $comment;
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
}

sub make_id_code($$$)
{
	my ($ip,$time,$email)=@_;

	return EMAIL_ID if($email and DISPLAY_ID==1);

	my @gmt=gmtime $time+9*60*60; # weird time offset copied from futaba
	my $date=sprintf '%04d%02d%02d',$gmt[5]+1900,$gmt[4]+1,$gmt[3];

	return substr(crypt(md5_hex($ip.'id'.$date),'id'),-8);
}

sub get_file_size($)
{
	my ($file)=@_;
	my (@filestats,$size);

	@filestats=stat $file;
	$size=$filestats[7];

	die S_TOOBIG if($size>MAX_KB*1024);
	die S_TOOBIGORNONE if($size==0); # check for small files, too?

	return($size);
}

sub process_file($$)
{
	my ($file,$time)=@_;
	my ($filename,$width,$height,$thumbnail,$tn_width,$tn_height);
	my ($sth,$ext,$filebase,$buffer,$md5ctx);

	# make sure to read file in binary mode on platforms that care about such things
	binmode $file;

	# analyze file and check that it's in a supported format
	($ext,$width,$height)=analyze_image($file);

	die S_BADFORMAT unless(ALLOW_UNKNOWN or $width);
	die S_BADFORMAT if(grep { $_ eq $ext } FORBIDDEN_EXTENSIONS);
	die S_TOOBIG if(MAX_IMAGE_WIDTH and $width>MAX_IMAGE_WIDTH);
	die S_TOOBIG if(MAX_IMAGE_HEIGHT and $height>MAX_IMAGE_HEIGHT);
	die S_TOOBIG if(MAX_IMAGE_PIXELS and $width*$height>MAX_IMAGE_PIXELS);

	$ext.=MUNGE_UNKNOWN unless($width);

	$filebase=$time.sprintf("%03d",int(rand(1000)));
	$filename=IMG_DIR.$filebase.'.'.$ext;

	# prepare MD5 checksum
	$md5ctx=Digest::MD5->new;

	# copy file
	open (OUTFILE,">>$filename") or die S_NOTWRITE;
	binmode OUTFILE;
	while (read($file,$buffer,1024)) # should the buffer be larger?
	{
		print OUTFILE $buffer;
		$md5ctx->add($buffer);
	}
	close $file;
	close OUTFILE;

	if(add_md5($filename,$md5ctx->hexdigest()))
	{
		unlink $filename; # make sure to remove the file
		die S_DUPE;
	}

	# thumbnail

	$thumbnail=THUMB_DIR.$filebase."s.jpg";

	if(!$width) # unsupported file
	{
		$thumbnail=undef;
	}
	elsif($width<=MAX_W and $height<=MAX_H) # small enough to display
	{
		$tn_width=$width;
		$tn_height=$height;

		if(THUMBNAIL_SMALL)
		{
			if(make_thumbnail($filename,$thumbnail,$tn_width,$tn_height))
			{
				if(-s $thumbnail >= -s $filename) # is the thumbnail larger than the original image?
				{
					unlink $thumbnail;
					$thumbnail=$filename;
				}
			}
			else
			{
				$thumbnail=undef;
			}
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

	return($filename,$width,$height,$thumbnail,$tn_width,$tn_height);
}



#
# Deleting
#

sub delete_stuff($$@)
{
	my ($password,$fileonly,@posts)=@_;

	foreach my $post (@posts)
	{
		my ($thread,$num)=$post=~/([0-9]+),([0-9]+)/;

		delete_post($thread,$num,$fileonly,$password);
	}

	build_all_main_pages();

	make_http_forward(HTML_SELF);
}

sub trim_pages()
{
	my @pages=get_pages(TRIM_METHOD);

	if(@pages>MAX_THREADS)
	{
		splice @pages,0,MAX_THREADS;

		my $regexp=RES_DIR.'([0-9]+)'.PAGE_EXT;
		foreach (@pages) { /$regexp/; delete_post($1,1,0,ADMIN_PASS);  }
	}
}

sub delete_post($$$$)
{
	my ($thread,$post,$fileonly,$password)=@_;
	my $logpass=find_password($thread,$post);
	my $encpass=encode_password($password);

	die S_BADDELPASS unless($password);
	die S_BADDELPASS unless($password eq ADMIN_PASS or $encpass eq $logpass);

	if($post==1 and !$fileonly)
	{
		my @thread=read_array(RES_DIR.$thread.PAGE_EXT);
		pop @thread; shift @thread;

		foreach my $post (@thread)
		{
			my ($image,$thumbnail)=get_images($post);
			unlink $image;
			unlink $thumbnail;
		}
		unlink RES_DIR.$thread.PAGE_EXT;
	}
	else
	{
		my @page=read_array(RES_DIR.$thread.PAGE_EXT);
		return unless(@page);

		my $index=get_post_index($post,@page);
		return unless($index);

		my ($image,$thumbnail)=get_images($page[$index]);
		unlink $image;
		unlink $thumbnail;

		unless($fileonly)
		{
			splice @page,$index,1;
			write_array(RES_DIR.$thread.PAGE_EXT,@page);
		}
	}
}



#
# Metadata access utils
#

sub get_pages($)
{
	my ($bumped)=@_;

	my @pages=glob(RES_DIR."*".PAGE_EXT);
	my @bumplist=read_bumplist();

	if($bumped)
	{
		foreach my $page (@bumplist)
		{
			my $pagename=RES_DIR.$page.PAGE_EXT;
			@pages=grep { $_ ne $pagename } @pages;
			unshift @pages,$pagename if(-e $pagename);
		}
	}
	else
	{
		my $re=RES_DIR.'([0-9]+)'.PAGE_EXT;
		@pages=sort { my ($c,$d); $a=~/$re/; $c=$1; $b=~/$re/; $d=$1; -($c<=>$d); } @pages;
	}

	return @pages;
}

sub get_post_index($@)
{
	my ($post,@page)=@_;
	for(my $i=1;$i<$#page;$i++) { return $i if(get_post_num($page[$i])==$post); }
	return 0;
}

sub get_post_num($) { return ($_[0]=~m!<span class="post_num">([0-9]+)</span>!)[0]; }

sub get_images($)
{
	my ($post)=@_;
	my $img_dir=expand_filename(IMG_DIR);
	my $thumb_dir=expand_filename(THUMB_DIR);

	my ($image)=$post=~/<a[^>]+href="$img_dir([^"]+)/;
	my ($thumbnail)=$post=~/<img[^>]+src="$thumb_dir([^"]+)/;

	$image=IMG_DIR.$image if($image);
	$thumbnail=THUMB_DIR.$thumbnail if($thumbnail);

	return ($image,$thumbnail);
}

sub find_password($$)
{
	my ($thread,$post)=@_;

	foreach(read_log())
	{
		my @data=split /\s*,\s*/;
		return $data[2] if($data[0]==$thread and $data[1]==$post);
	}
	return undef;
}

sub add_bump($)
{
	my ($thread)=@_;

	my @bumplist=read_bumplist();
	@bumplist=grep { $_!=$thread } @bumplist;
	push @bumplist,$thread;
	write_bumplist(@bumplist);
}

sub add_log($$$$)
{
	my ($thread,$post,$password,$ip)=@_;

	$password=encode_password($password);
	$ip=encode_ip($ip);

	my @log=read_log();
	unshift @log,"$thread,$post,$password,$ip";
	write_log(@log);
}

sub add_md5($$)
{
	my ($filename,$md5)=@_;

	my @md5=read_md5();
	return 1 if(grep { /,(.*)$/; $md5 eq $1; } @md5);
	push @md5,"$filename,$md5\n";
	write_md5(@md5);

	return 0;
}

sub add_key($)
{
	my ($key)=@_;

	my @keys=read_keys();
	return 1 if(grep { $key eq $_ } @keys);
	push @keys,$key;
	@keys=splice @keys,-(MAX_KEY_LOG) if(@keys>=MAX_KEY_LOG);
	write_keys(@keys);

	return 0;
}

sub read_bumplist() { return grep { -e RES_DIR.$_.PAGE_EXT } read_array("bump.txt"); }
sub write_bumplist(@) { write_array("bump.txt",@_); }
sub read_log() { return grep { /^([0-9]+)/; -e RES_DIR.$1.PAGE_EXT } read_array("log.txt"); }
sub write_log(@) { write_array("log.txt",@_); }
sub read_md5() { return grep { /^(.*?),/; -e $1 } read_array("md5.txt"); }
sub write_md5(@) { write_array("md5.txt",@_); }
sub read_keys() { read_array("keys.txt"); }
sub write_keys(@) { write_array("keys.txt",@_); }

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

sub write_array($)
{
	my ($filename,@array)=@_;

	open FILE,">$filename" or die S_NOTWRITE;
	print FILE join "\n",@array;
	close FILE;
}

sub encode_password($) { return substr md5_base64(SECRET.$_[0]),0,8; }
sub encode_ip($) { my $iv=make_iv(); return $iv.'!'.encode_base64(rc4($_[0],md5(SECRET.$iv)),''); }

sub make_iv()
{
	my $iv;
	my $chars="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

	$iv.=substr $chars,rand length $chars,1 for(0..7);

	return $iv;
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



#
# Page creation utils
#

sub make_template($%)
{
	my ($src,%vars)=@_;

	$vars{self}=$ENV{SCRIPT_NAME};

	my $res=expand_template($src,%vars);

	$res=~s/(src|href|action)="([^#].*?)"/
		$1.'="'.expand_filename($2).'"'
	/gei;

	$res=~s/\s+/ /sg;

	return $res;
}

sub expand_template($%)
{
	my ($str,%vars)=@_;
	my ($vardefs,$blocks,$singles);

	$vardefs.="my \$$_=\$vars{$_};" for(keys %vars);

	$blocks=qr(
		\<(if|loop)(?:|\s+([^\>]*))\>
		((?:
			(?>[^\<]+)
		|
			\<(?!/?(?:if|loop)(?:|\s+[^\>]*)\>)
		|
			(??{$blocks})
		)*)
		\</(?:\1)\>
	)x;
	$singles=qr(\<(var)(?:|\s+(.*?)/?)\>);

	$str=~s/(?:$blocks|$singles)/
		my ($btag,$barg,$bdata,$stag,$sarg)=($1,$2,$3,$4,$5);

		if($stag eq 'var')
		{
			eval $vardefs.$sarg;
		}
		elsif($btag eq 'if')
		{
			eval $vardefs.$barg ? expand_template($bdata,%vars) : '';
		}
		elsif($btag eq 'loop')
		{
			join '',map { expand_template($bdata,(%vars,%$_)) } @{eval $vardefs.$barg};
		}
	/sge;

	return $str;
}

sub expand_filename($)
{
	my ($filename)=@_;
	return $filename if($filename=~m!^/!);
	return $filename if($filename=~m!^\w+:!);

	my ($self_path)=$ENV{SCRIPT_NAME}=~m!^(.*/)[^/]+$!;
	return $self_path.$filename;
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

sub make_cookies(%)
{
	my (%cookies)=@_;
	my ($cookie);

	foreach my $name (keys %cookies)
	{
		my $value=defined($cookies{$name})?$cookies{$name}:'';
		$value=decode(CHARSET,$value);
		$value=join '',map { my $c=ord($_); sprintf($c>255?'%%u%04x':'%%%02x',$c); } split //,$value;

		my $cookie=$query->cookie(-name=>$name,
		                          -value=>$value,
		                          -expires=>'+14d');

		$cookie=~s/%25/%/g; # repair encoding damage

		print "Set-Cookie: $cookie\n";
	}
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
	return(0);
}
