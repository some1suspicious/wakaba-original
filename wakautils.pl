use strict;

use Time::Local;



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
		my @hidden;

		# hide <code> sections
		$line=~s{ (?<![\x80-\x9f\xe0-\xfc]) (`+) ([^<>]+?) (?<![\x80-\x9f\xe0-\xfc]) \1}{push @hidden,"<code>$2</code>"; "<!--$#hidden-->"}sgex;

		# make URLs into links and hide them
		$line=~s{(https?://[^\s<>"]*?)((?:\s|<|>|"|\.|\)|\]|!|\?|,|&#44;|&quot;)*(?:[\s<>"]|$))}
		{push @hidden,"<a href=\"$1\">$1\</a>"; "<!--$#hidden-->$2"}sge;

		# do <strong>
		$line=~s{ (?<![0-9a-zA-Z\*_\x80-\x9f\xe0-\xfc]) (\*\*|__) (?![<>\s\*_]) ([^<>]+?) (?<![<>\s\*_\x80-\x9f\xe0-\xfc]) \1 (?![0-9a-zA-Z\*_]) }{<strong>$2</strong>}gx;

		# do <em>
		$line=~s{ (?<![0-9a-zA-Z\*_\x80-\x9f\xe0-\xfc]) (\*|_) (?![<>\s\*_]) ([^<>]+?) (?<![<>\s\*_\x80-\x9f\xe0-\xfc]) \1 (?![0-9a-zA-Z\*_]) }{<em>$2</em>}gx;

		$line=$handler->($line) if($handler);

		# fix up hidden sections
		$line=~s{<!--([0-9]+)-->}{$hidden[$1]}ge;

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

	my $port=$ENV{SERVER_PORT}==80?"":":$ENV{SERVER_PORT}";
	my $self=$ENV{SCRIPT_NAME};
	my $absolute_self="http://$ENV{SERVER_NAME}$port$ENV{SCRIPT_NAME}";
	my ($path)=$ENV{SCRIPT_NAME}=~m!^(.*/)[^/]+$!;
	my $absolute_path="http://$ENV{SERVER_NAME}$port$path";

	return eval
		'no strict; sub { '.
		'my %__v=@_;my %__ov;for(keys %__v){$__ov{$_}=$$_;$$_=$__v{$_};}'.
		'my $res;'.
		$code.
		'$$_=$__ov{$_} for(keys %__ov);'.
		'return $res; }';
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

	$str=~s/&/&amp;/g;
	$str=~s/\</&lt;/g;
	$str=~s/\>/&gt;/g;
	$str=~s/"/&quot;/g; #"
	$str=~s/'/&#39;/g;
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

	my $charset=$cookies{'-charset'};
	my $expires=($cookies{'-expires'} or time+14*24*3600);
	my $autopath=$cookies{'-autopath'};
	my $path=$cookies{'-path'};

	my $date=make_date($expires,"cookie");

	unless($path)
	{
		if($autopath eq 'current') { ($path)=$ENV{SCRIPT_NAME}=~m!^(.*/)[^/]+$! }
		elsif($autopath eq 'parent') { ($path)=$ENV{SCRIPT_NAME}=~m!^(.*?/)(?:[^/]+/)?[^/]+$! }
		else { $path='/'; }
	}

	foreach my $name (keys %cookies)
	{
		next if($name=~/^-/); # skip entries that start with a dash

		my $value=$cookies{$name};
		$value="" unless(defined $value);

		$value=cookie_encode($value,$charset);

		print "Set-Cookie: $name=$value; path=$path; expires=$date;\n";
	}
}

sub urlenc($)
{
	my ($str)=@_;
	$str=~s/([^\w ])/"%".sprintf("%02x",ord($1))/sge;
	$str=~s/ /+/sg;
	return $str;
}

sub cookie_encode($;$)
{
	my ($str,$charset)=@_;

	if($]>5.007) # new perl, use Encode.pm
	{
		if($charset)
		{
			require Encode;
			$str=Encode::decode($charset,$str);
			$str=~s/&\#([0-9]+);/chr($1)/ge;
		}

		$str=~s/([^0-9a-zA-Z])/
			my $c=ord($1);
			sprintf($c>255?'%%u%04x':'%%%02x',$c);
		/sge;
	}
	else # do the hard work ourselves
	{
		if($charset=~/\butf-?8$/i)
		{
			$str=~s{([\xe0-\xef][\x80-\xBF][\x80-\xBF]|[\xc0-\xdf][\x80-\xBF]|&#([0-9]+);|[^0-9a-zA-Z])}{ # convert UTF-8 to URL encoding - only handles up to U-FFFF
				my $c;
				if($2) { $c=$2 }
				elsif(length $1==1) { $c=ord($1) }
				elsif(length $1==2)
				{
					my @b=map { ord($_) } split //,$1;
					$c=(($b[0]-0xc0)<<6)+($b[1]-0x80);
				}
				elsif(length $1==3)
				{
					my @b=map { ord($_) } split //,$1;
					$c=(($b[0]-0xe0)<<12)+(($b[1]-0x80)<<6)+($b[2]-0x80);
				}
				sprintf($c>255?'%%u%04x':'%%%02x',$c);
			}sge;
		}
		elsif($charset=~/\b(?:shift.*jis|sjis)$/i) # old perl, using shift_jis
		{
			require 'sjis.pl';
			my $sjis_table=get_sjis_table();

			$str=~s{([\x80-\x9f\xe0-\xfc].|&#([0-9]+);|[^0-9a-zA-Z])}{ # convert Shift_JIS to URL encoding
				my $c=($2 or $$sjis_table{$1});
				sprintf($c>255?'%%u%04x':'%%%02x',$c);
			}sge;
		}
		else
		{
			$str=~s/([^0-9a-zA-Z])/sprintf('%%%02x',ord($1))/sge;
		}
	}

	return $str;
}



#
# Data utilities
#

sub process_tripcode($;$$)
{
	my ($name,$tripkey,$secret)=@_;
	$tripkey="!" unless($tripkey);

	if($name=~/^(.*?)(#|\Q$tripkey\E)(.*)$/)
	{
		my ($namepart,$marker,$trippart)=($1,$2,$3);
		my $trip;

#		eval 'use Digest::MD5 qw(md5_base64)'; # check to see if we can do MD5
#		if(!$@ and $secret and $trippart=~s/(?:\Q$marker\E)+(.*)$//) # do we want secure trips, and is there one?
#		{
#			$trip=$tripkey.$tripkey.substr md5_base64($secret.$1),0,8;
#			return ($namepart,$trip) unless($trippart); # return directly if there's no normal tripcode
#		}

		if($secret and $trippart=~s/(?:\Q$marker\E)+(.*)$//) # do we want secure trips, and is there one?
		{
			$trip=$tripkey.$tripkey.encode_base64(rc4(null_string(6),"t".$1.$secret),"");
			return ($namepart,$trip) unless($trippart); # return directly if there's no normal tripcode
		}

		my $salt=substr $trippart."H..",1,2;
		$salt=~s/[^\.-z]/./g;
		$salt=~tr/:;<=>?@[\\]^_`/ABCDEFGabcdef/; 
		$trip=$tripkey.(substr crypt($trippart,$salt),-10).$trip;

		return ($namepart,$trip);
	}

	return ($name,"");
}

sub make_date($$;@)
{
	my ($time,$style,@locdays)=@_;
	my @days=qw(Sun Mon Tue Wed Thu Fri Sat);
	my @months=qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
	@locdays=@days unless(@locdays);

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
		$ltime[5]-100,$ltime[4]+1,$ltime[3],$locdays[$ltime[6]],$ltime[2],$ltime[1]);
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
		$days[$wday],$mday,$months[$mon],$year+1900,$hour,$min,$sec);
	}
	elsif($style eq "cookie")
	{
		my ($sec,$min,$hour,$mday,$mon,$year,$wday)=gmtime($time);
		return sprintf("%s, %02d-%s-%04d %02d:%02d:%02d GMT",
		$days[$wday],$mday,$months[$mon],$year+1900,$hour,$min,$sec);
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

sub cfg_expand($%)
{
	my ($str,%grammar)=@_;
	$str=~s/%(\w+)%/
		my @expansions=@{$grammar{$1}};
		cfg_expand($expansions[rand @expansions],%grammar);
	/ge;
	return $str;
}

sub encode_base64($;$) # stolen from MIME::Base64::Perl
{
	my ($data,$eol)=@_;
	$eol="\n" unless(defined $eol);

	my $res=pack "u",$data;
	$res=~s/^.//mg; # remove length counts
	$res=~s/\n//g; # remove newlines
	$res=~tr|` -_|AA-Za-z0-9+/|; # translate to base64

	my $padding=(3-length($data)%3)%3; 	# fix padding at the end
	$res=~s/.{$padding}$/'='x$padding/e if($padding);

	$res=~s/(.{1,76})/$1$eol/g if(length $eol); # break encoded string into lines of no more than 76 characters each

	return $res;
}

sub decode_base64($) # stolen from MIME::Base64::Perl
{
	my ($str)=@_;

	$str=~tr|A-Za-z0-9+=/||cd;	# remove non-base64 characters
	$str=~s/=+$//; # remove padding
	$str=~tr|A-Za-z0-9+/| -_|; # translate to uuencode
	return "" unless(length $str);
	return unpack "u",join '',map { chr(32+length($_)*3/4).$_ } $str=~/(.{1,60})/gs;
}

sub make_random_string($)
{
	my ($num)=@_;
	my $chars="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
	my $str;

	$str.=substr $chars,rand length $chars,1 for(1..$num);

	return $str;
}

sub null_string($) { "\0"x(shift) }



#
# File utilities
#

sub read_array($)
{
	my ($file)=@_;

	if(ref $file eq "GLOB")
	{
		return map { s/\r?\n?$//; $_ } <$file>;
	}
	else
	{
		open FILE,$file or return ();
		my @array=map { s/\r?\n?$//; $_ } <FILE>;
		close FILE;
		return @array;
	}
}

sub write_array($@)
{
	my ($file,@array)=@_;

	if(ref $file eq "GLOB")
	{
		print $file join "\n",@array;
	}
	else
	{
		open FILE,">$file" or die "Couldn't write to directory";
		print FILE join "\n",@array;
		close FILE;
	}
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

sub make_thumbnail($$$$$;$)
{
	my ($filename,$thumbnail,$width,$height,$quality,$convert)=@_;

	# first try ImageMagick

	my $magickname=$filename;
	$magickname.="[0]" if($magickname=~/\.gif$/);

	$convert="convert" unless($convert);
	`$convert -size ${width}x${height} -geometry ${width}x${height}! -quality $quality $magickname $thumbnail`;

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


#
# Crypto code
#

sub rc4($$;$)
{
	my ($message,$key,$skip)=@_;
	my @s=0..255;
	my @k=unpack 'C*',$key;
	my @message=unpack 'C*',$message;
	my ($x,$y);
	$skip=256 unless(defined $skip);

	$y=0;
	for $x (0..255)
	{
		$y=($y+$s[$x]+$k[$x%@k])%256;
		@s[$x,$y]=@s[$y,$x];
	}

	$x=0; $y=0;
	for(1..$skip)
	{
		$x=($x+1)%256;
		$y=($y+$s[$x])%256;
		@s[$x,$y]=@s[$y,$x];
	}

	for(@message)
	{
		$x=($x+1)%256;
		$y=($y+$s[$x])%256;
		@s[$x,$y]=@s[$y,$x];
		$_^=$s[($s[$x]+$s[$y])%256];
	}

	return pack 'C*',@message;
}

my @S;

sub setup_rc6($)
{
	my ($key)=@_;

	$key.="\0"x(4-(length $key)&3); # pad key

	my @L=unpack "V*",$key;

	$S[0]=0xb7e15163;
	$S[$_]=add($S[$_-1],0x9e3779b9) for(1..43);

	my $v=@L>44 ? @L*3 : 132;
	my ($A,$B,$i,$j);

	for(1..$v)
	{
		$A=$S[$i]=rol(add($S[$i],$A,$B),3);
		$B=$L[$j]=rol(add($L[$j]+$A+$B),add($A+$B));
		$i=($i+1)%@S;
		$j=($j+1)%@L;	
	}
}

sub encrypt_rc6($)
{
	my ($block,)=@_;
	my ($A,$B,$C,$D)=unpack "V4",$block."\0"x16;

	$B=add($B,$S[0]);
	$D=add($D,$S[1]);

	for(my $i=1;$i<=20;$i++)
	{
		my $t=rol(mul($B,rol($B,1)|1),5);
		my $u=rol(mul($D,rol($D,1)|1),5);
		$A=add(rol($A^$t,$u),$S[2*$i]);
		$C=add(rol($C^$u,$t),$S[2*$i+1]);

		($A,$B,$C,$D)=($B,$C,$D,$A);
	}

	$A=add($A,$S[42]);
	$C=add($C,$S[43]);
		
	return pack "V4",$A,$B,$C,$D;
}

sub decrypt_rc6($)
{
	my ($block,)=@_;
	my ($A,$B,$C,$D)=unpack "V4",$block."\0"x16;

	$C=add($C,-$S[43]);
	$A=add($A,-$S[42]);

	for(my $i=20;$i>=1;$i--)
	{
		($A,$B,$C,$D)=($D,$A,$B,$C);
		my $u=rol(mul($D,add(rol($D,1)|1)),5);
		my $t=rol(mul($B,add(rol($B,1)|1)),5);
		$C=ror(add($C,-$S[2*$i+1]),$t)^$u;
		$A=ror(add($A,-$S[2*$i]),$u)^$t;

	}

	$D=add32($D,-$S[1]);
	$B=add32($B,-$S[0]);
		
	return pack "V4",$A,$B,$C,$D;
}

sub add(@) { my ($sum,$term); while(defined ($term=shift)) { $sum+=$term } return $sum%4294967296 }
sub rol($$) { my ($x,$n); ( $x = shift ) << ( $n = 31 & shift ) | 2**$n - 1 & $x >> 32 - $n; }
sub ror($$) { rol(shift,32-(31&shift)); } # rorororor
sub mul($$) { my ($a,$b)=@_; return ( (($a>>16)*($b&65535)+($b>>16)*($a&65535))*65536+($a&65535)*($b&65535) )%4294967296 }

1;
