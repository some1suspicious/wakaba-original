use strict;

use CGI;


BEGIN
{
	use constant 1.01; # don't omit this! ...tte iu no ka
	eval "use constant CONVERT_COMMAND => 'convert'" unless($constant::declared{"main::CONVERT_COMMAND"});
	eval "use constant CHARSET => 'utf-8'" unless($constant::declared{"main::CHARSET"});
	eval "use constant S_NOTWRITE => 'Couldn\\'t write to file'" unless($constant::declared{"main::S_NOTWRITE"});
	eval "use constant S_WEEKDAYS => ('Sun','Mon','Tue','Wed','Thu','Fri','Sat')" unless($constant::declared{"main::S_WEEKDAYS"});
}



#
# HTML utilities
#

sub abbreviate_html($$$)
{
	my ($html,$max_lines,$approx_len)=@_;
	my ($lines,$chars,@stack);

	return undef unless($max_lines);

	while($html=~m!(?:([^<]+)|<(/?)(\w+).*?(/?)>)!g)
	{
		my ($text,$closing,$tag,$implicit)=($1,$2,lc($3),$4);

		if($text) { $chars+=length $text; }
		else
		{
			push @stack,$tag if(!$closing and !$implicit);
			pop @stack if($closing);

			if(($closing or $implicit) and ($tag eq "p" or $tag eq "blockquote" or $tag eq "pre"
			or $tag eq "li" or $tag eq "ol" or $tag eq "ul" or $tag eq "br"))
			{
				$lines+=int($chars/$approx_len)+1;
				$lines++ if($tag eq "p" or $tag eq "blockquote");
				$chars=0;
			}

			if($lines>=$max_lines)
			{
 				# check if there's anything left other than end-tags
 				return undef if((substr $html,pos $html)=~m!^(?:\s*</\w+>)*$!);

				my $abbrev=substr $html,0,pos $html;
				while(my $tag=pop @stack) { $abbrev.="</$tag>" }

				return $abbrev;
			}
		}
	}

	return undef;
}

sub do_wakabamark($@)
{
	my ($handler,$simplify,@lines)=@_;
	my $res;

	while(defined($_=$lines[0]))
	{
		if(/^\s*$/) { shift @lines; } # skip empty lines
		elsif(/^(1\.|[\*\+\-]) .*/) # lists
		{
			my ($tag,$re,$html);

			if($1 eq "1.") { $tag="ol"; $re=qr/[0-9]+\./; }
			else { $tag="ul"; $re=qr/\Q$1\E/; }

			while($lines[0]=~/^($re)(?: |\t)(.*)/)
			{
				my $spaces=(length $1)+1;
				my @item=($2);
				shift @lines;

				while($lines[0]=~/^(?: {1,$spaces}|\t)(.*)/) { push @item,$1; shift @lines }
				$html.="<li>".do_wakabamark($handler,1,@item)."</li>";
			}
			$res.="<$tag>$html</$tag>";
		}
		elsif(/^(?:    |\t).*/) # code sections
		{
			my @code;
			while($lines[0]=~/^(?:    |\t)(.*)/) { push @code,$1; shift @lines; }
			$res.="<pre><code>".(join "<br />",@code)."</code></pre>";
		}
		elsif(/^&gt;.*/) # quoted sections
		{
			my @quote;
			while($lines[0]=~/^(&gt;.*)/) { push @quote,$1; shift @lines; }
			$res.="<blockquote>".do_spans($handler,@quote)."</blockquote>";

			#while($lines[0]=~/^&gt;(.*)/) { push @quote,$1; shift @lines; }
			#$res.="<blockquote>".do_blocks($handler,@quote)."</blockquote>";
		}
		else # normal paragraph
		{
			my @text;
			while($lines[0]!~/^(?:\s*$|1\. |[\*\+\-] |&gt;|    |\t)/) { push @text,shift @lines; }
			if(!defined($lines[0]) and $simplify) { $res.=do_spans($handler,@text) }
			else { $res.="<p>".do_spans($handler,@text)."</p>" }
		}
		$simplify=0;
	}
	return $res;
}

sub do_spans($@)
{
	my $handler=shift;
	return join "<br />",map
	{
		my $line=$_;
		my @codespans;

		# hide <code> sections
		$line=~s{(`+)([^<>]+?)\1}{push @codespans,$2; "<code></code>"}ge;

		# make URLs into links
		$line=~s{(https?://[^\s<>"]*?)((?:\s|<|>|"|\.|\)|\]|!|\?|,|&#44;|&quot;)*(?:[\s<>"]|$))}{\<a href="$1"\>$1\</a\>$2}sgi;

		# do <strong>
		$line=~s{([^0-9a-zA-Z\*_]|^)(\*\*|__)([^<>\s\*_](?:[^<>]*?[^<>\s\*_])?)\2(?=[^0-9a-zA-Z\*_]|$)}{$1<strong>$3</strong>}g;

		# do <em>
		$line=~s{([^0-9a-zA-Z\*_]|^)(\*|_)([^<>\s\*_](?:[^<>]*?[^<>\s\*_])?)\2(?=[^0-9a-zA-Z\*_]|$)}{$1<em>$3</em>}g;

		$line=$handler->($line) if($handler);

		# fix up <code> sections
		$line=~s{<code></code>}{"<code>".(shift @codespans)."</code>"}ge;

		$line;
	} @_;
}

sub compile_template($%)
{
	my ($str)=@_;
	my $code;

	$str=~s/^\s+//;
	$str=~s/\s+$//;
	$str=~s/\n\s*/ /sg;

	while($str=~m!(.*?)(<(/?)(var|const|if|loop)(?:|\s+([^>]*))>|$)!sg)
	{
		my ($html,$tag,$closing,$name,$args)=($1,$2,$3,$4,$5);

		$html=~s/(['\\])/\\$1/g;
		$code.="\$res.='$html';" if(length $html);

		if($tag)
		{
			if($closing)
			{
				if($name eq 'if') { $code.='}' }
				elsif($name eq 'loop') { $code.='$$_=$__ov{$_} for(keys %__ov);}' }
			}
			else
			{
				if($name eq 'var') { $code.='$res.=eval{'.$args.'};' }
				elsif($name eq 'const') { my $const=eval $args; $const=~s/(['\\])/\\$1/g; $code.='$res.=\''.$const.'\';' }
				elsif($name eq 'if') { $code.='if(eval{'.$args.'}){' }
				elsif($name eq 'loop')
				{ $code.='for(@{(eval{'.$args.'})}){my %__v=%{$_};my %__ov;for(keys %__v){$__ov{$_}=$$_;$$_=$__v{$_};}' }
			}
		}
	}

	return eval
		'no strict; sub { '.
		'my $port=$ENV{SERVER_PORT}==80?"":":$ENV{SERVER_PORT}";'.
		'my $self=$ENV{SCRIPT_NAME};'.
		'my $absolute_self="http://$ENV{SERVER_NAME}$port$ENV{SCRIPT_NAME}";'.
		'my ($path)=$ENV{SCRIPT_NAME}=~m!^(.*/)[^/]+$!;'.
		'my $absolute_path="http://$ENV{SERVER_NAME}$port$path";'.
		'my %__v=@_;my %__ov;for(keys %__v){$__ov{$_}=$$_;$$_=$__v{$_};}'.
		'my $res;'.
		$code.
		'$$_=$__ov{$_} for(keys %__ov);'.
		'return $res; }';
}

sub urlenc($)
{
	my ($str)=@_;
	$str=~s/([^\w ])/"%".sprintf("%02x",ord($1))/sge;
	$str=~s/ /+/sg;
	return $str;
}

sub include($)
{
	my ($filename)=@_;

	open FILE,$filename or return '';
	my $file=do { local $/; <FILE> };

	$file=~s/^\s+//;
	$file=~s/\s+$//;
	$file=~s/\n\s*/ /sg;

	return $file;
}

sub clean_string($)
{
	my ($str)=@_;

	# $str=~s/^\s*//; # remove preceeding whitespace
	# $str=~s/\s*$//; # remove traling whitespace

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


#
# HTTP utilities
#

sub make_http_forward($;$)
{
	my ($location,$alternate_method)=@_;

	if($alternate_method)
	{
		print "Content-Type: text/html\n";
		print "\n";
		print "<html><head>";
		print '<meta http-equiv="refresh" content="0; url='.$location.'" />';
		print '<script type="text/javascript">document.location="'.$location.'";</script>';
		print '</head><body><a href="'.$location.'">'.$location.'</a></body></html>';
	}
	else
	{
		print "Status: 301 Go West\n";
		print "Location: $location\n";
		print "Content-Type: text/html\n";
		print "\n";
		print '<html><body><a href="'.$location.'">'.$location.'</a></body></html>';
	}
}

sub make_cookies(%)
{
	my (%cookies)=@_;
	my ($cookie);

	foreach my $name (keys %cookies)
	{
		my $value=defined($cookies{$name})?$cookies{$name}:'';
		my $cookie;

		eval 'use Encode qw(decode)'; # check to see if we can do character sets.
		unless($@)
		{
			$value=decode(CHARSET,$value);
			$value=join '',map { my $c=ord($_); sprintf($c>255?'%%u%04x':'%%%02x',$c); } split //,$value;

			$cookie=CGI::cookie(-name=>$name,
			                    -value=>$value,
			                    -expires=>'+14d');

			$cookie=~s/%25/%/g; # repair encoding damage
		}
		else
		{
			$cookie=CGI::cookie(-name=>$name,
			                    -value=>$value,
			                    -expires=>'+14d');
		}

		print "Set-Cookie: $cookie\n";
	}
}



#
# Data utilities
#

sub process_tripcode($;$$)
{
	my ($name,$tripkey,$secret)=@_;

	if($name=~/^(.*?)(#|\Q$tripkey\E)(.*)$/)
	{
		my ($namepart,$marker,$trippart)=($1,$2,$3);
		my $trip;

		eval 'use Digest::MD5 qw(md5_base64)'; # check to see if we can do MD5
		if(!$@ and $secret and $trippart=~s/(?:\Q$marker\E)+(.*)$//) # do we want secure trips, and is there one?
		{
			$trip=TRIPKEY.TRIPKEY.substr md5_base64($secret.$1),0,8;
			return ($namepart,$trip) unless($trippart); # return directly if there's no normal tripcode
		}

		my $salt=substr $trippart."H..",1,2;
		$salt=~s/[^\.-z]/./g;
		$salt=~tr/:;<=>?@[\\]^_`/ABCDEFGabcdef/; 
		$trip=TRIPKEY.(substr crypt($trippart,$salt),-10).$trip;

		return ($namepart,$trip);
	}

	return ($name,"");
}

sub make_date($$)
{
	my ($time,$style)=@_;

	if($style eq "2ch")
	{
		my @ltime=localtime($time);

		return sprintf("%04d-%02d-%02d %02d:%02d",
		$ltime[5]+1900,$ltime[4]+1,$ltime[3],$ltime[2],$ltime[1]);
	}
	elsif($style eq "futaba" or $style eq "0")
	{
		my @ltime=localtime($time);

		return sprintf("%02d/%02d/%02d(%s)%02d:%02d",
		$ltime[5]-100,$ltime[4]+1,$ltime[3],(S_WEEKDAYS)[$ltime[6]],$ltime[2],$ltime[1]);
	}
	elsif($style eq "localtime")
	{
		return scalar(localtime($time));
	}
	elsif($style eq "tiny")
	{
		my @ltime=localtime($time);

		return sprintf("%02d/%02d %02d:%02d",
		$ltime[4]+1,$ltime[3],$ltime[2],$ltime[1]);
	}
	elsif($style eq "http")
	{
		my ($sec,$min,$hour,$mday,$mon,$year,$wday)=gmtime($time);
		return sprintf("%s, %02d %s %04d %02d:%02d:%02d GMT",
		qw(Sun Mon Tue Wed Thu Fri Sat)[$wday],$mday,
		qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)[$mon],
		$year+1900,$hour,$min,$sec);
	}
}



sub parse_http_date($)
{
	my ($date)=@_;
	my %months=(Jan=>0,Feb=>1,Mar=>2,Apr=>3,May=>4,Jun=>5,Jul=>6,Aug=>7,Sep=>8,Oct=>9,Nov=>10,Dec=>11);

	if($date=~/^[SMTWF][a-z][a-z], (\d\d) ([JFMASOND][a-z][a-z]) (\d\d\d\d) (\d\d):(\d\d):(\d\d) GMT$/)
	{ return eval { timegm($6,$5,$4,$1,$months{$2},$3-1900) } }

	return undef;
}

sub make_random_string($)
{
	my ($num)=@_;
	my $chars="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
	my $str;

	$str.=substr $chars,rand length $chars,1 for(1..$num);

	return $str;
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



#
# File utilities
#

sub read_array($)
{
	my ($filename)=@_;

	open FILE,$filename or return ();
	my @array=map { s/\r?\n?$//; $_ } <FILE>;
	close FILE;

	return @array;
}

sub write_array($@)
{
	my ($filename,@array)=@_;

	open FILE,">$filename" or die S_NOTWRITE;
	print FILE join "\n",@array;
	close FILE;
}



#
# Spam utilities
#

sub spam_check($$)
{
	my ($text,$spamfile)=@_;
	my @spam=read_spam_file($spamfile);

	foreach (@spam) { return 1 if($text=~/\Q$_\E/) }
	return 0;
}

sub read_spam_file($)
{
	return grep { length $_ } map { s/#.*//; s/^\s+//; s/\s+$//; $_; }  read_array(shift);
}



#
# Image utilities
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
			die "Possible virus in image" if($size<2); # MS GDI+ JPEG exploit uses short chunks

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

sub make_thumbnail($$$$$)
{
	my ($filename,$thumbnail,$width,$height,$quality)=@_;

	# first try ImageMagick

	my $magickname=$filename;
	$magickname.="[0]" if($magickname=~/\.gif$/);

	my $convert=CONVERT_COMMAND;
	`$convert -size ${width}x$height -geometry ${width}x${height}! -quality $quality $magickname $thumbnail`;

	return 1 unless($?);

	# if that fails, try pnmtools instead

	if($filename=~/\.jpg$/)
	{
		`djpeg $filename | pnmscale -width $width -height $height | cjpeg -quality $quality > $thumbnail`;
		# could use -scale 1/n
		return 1 unless($?);
	}
	elsif($filename=~/\.png$/)
	{
		`pngtopnm $filename | pnmscale -width $width -height $height | cjpeg -quality $quality > $thumbnail`;
		return 1 unless($?);
	}
	elsif($filename=~/\.gif$/)
	{
		`giftopnm $filename | pnmscale -width $width -height $height | cjpeg -quality $quality > $thumbnail`;
		return 1 unless($?);
	}

	# try PerlMagick last, because it sucks ass.

	eval 'use Image::Magick';
	unless($@)
	{
		my ($res,$magick);

		$magick=Image::Magick->new;

		$res=$magick->Read($magickname);
		return 0 if "$res";
		$res=$magick->Scale(width=>$width, height=>$height);
		#return 0 if "$res";
		$res=$magick->Write(filename=>$thumbnail, quality=>$quality);
		#return 0 if "$res";

		return 1;
	}

	return 0;
}

1;
