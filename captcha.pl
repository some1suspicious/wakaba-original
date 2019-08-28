#!/usr/bin/perl

use strict;

use CGI;
use DBI;

use lib '.';
BEGIN { require "config.pl"; }
BEGIN { require "strings_e.pl"; }




my $font_height=16;
my %font=
(
	a=>[10,[10],[10],[10],[10],[2,4,4],[1,7,2],[1,1,3,3,2],[4,4,2],[1,3,1,3,2],[0,3,2,3,2],[0,9,1],[1,3,2,2,2],[10],[10],[10],[10]],
	b=>[10,[0,3,7],[0,3,7],[0,3,7],[0,3,7],[0,3,1,3,3],[0,8,2],[0,3,3,3,1],[0,3,3,3,1],[0,3,3,3,1],[0,3,3,3,1],[0,3,3,2,2],[0,1,2,4,3],[10],[10],[10],[10]],
	c=>[8,[8],[8],[8],[8],[2,3,3],[1,6,1],[0,3,2,1,2],[0,3,5],[0,3,5],[0,3,3,1,1],[1,5,2],[2,4,2],[8],[8],[8],[8]],
	d=>[9,[5,3,1],[5,3,1],[5,3,1],[5,3,1],[2,2,1,3,1],[1,7,1],[0,3,2,3,1],[0,3,2,3,1],[0,3,2,3,1],[0,3,2,3,1],[1,7,1],[2,2,1,3,1],[9],[9],[9],[9]],
	e=>[9,[9],[9],[9],[9],[2,4,3],[1,2,2,2,2],[0,3,2,3,1],[0,8,1],[0,3,6],[0,4,3,1,1],[1,6,2],[3,3,3],[9],[9],[9],[9]],
	f=>[7,[3,3,1],[2,3,2],[1,2,4],[1,2,4],[0,5,2],[1,3,3],[1,3,3],[1,3,3],[1,3,3],[1,3,3],[1,3,3],[1,3,3],[7],[7],[7],[7]],
	g=>[11,[11],[11],[11],[11],[2,7,2],[1,3,1,3,3],[1,3,1,3,3],[1,3,1,3,3],[2,4,5],[2,2,7],[1,8,2],[2,8,1],[2,8,1],[0,2,5,3,1],[0,2,5,2,2],[1,6,4]],
	h=>[9,[0,3,6],[0,3,6],[0,3,6],[0,3,6],[0,3,1,3,2],[0,8,1],[0,3,2,3,1],[0,3,2,3,1],[0,3,2,3,1],[0,3,2,3,1],[0,3,2,3,1],[0,3,2,3,1],[9],[9],[9],[9]],
	i=>[4,[1,1,2],[0,3,1],[0,2,2],[4],[0,3,1],[0,3,1],[0,3,1],[0,3,1],[0,3,1],[0,3,1],[0,3,1],[0,3,1],[4],[4],[4],[4]],
	j=>[6,[3,1,2],[2,3,1],[2,2,2],[6],[2,3,1],[2,3,1],[2,3,1],[2,3,1],[2,3,1],[2,3,1],[2,3,1],[2,3,1],[2,3,1],[2,3,1],[2,2,2],[0,3,3]],
	k=>[9,[0,3,6],[0,3,6],[0,3,6],[0,3,6],[0,3,2,3,1],[0,3,2,2,2],[0,3,1,2,3],[0,6,3],[0,6,3],[0,7,2],[0,3,1,4,1],[0,3,2,3,1],[9],[9],[9],[9]],
	l=>[4,[0,3,1],[0,3,1],[0,3,1],[0,3,1],[0,3,1],[0,3,1],[0,3,1],[0,3,1],[0,3,1],[0,3,1],[0,3,1],[0,3,1],[4],[4],[4],[4]],
	m=>[14,[14],[14],[14],[14],[0,3,1,3,2,3,2],[0,13,1],[0,3,2,3,2,3,1],[0,3,2,3,2,3,1],[0,3,2,3,2,3,1],[0,3,2,3,2,3,1],[0,3,2,3,2,3,1],[0,3,2,3,2,3,1],[14],[14],[14],[14]],
	n=>[9,[9],[9],[9],[9],[0,3,1,3,2],[0,8,1],[0,3,2,3,1],[0,3,2,3,1],[0,3,2,3,1],[0,3,2,3,1],[0,3,2,3,1],[0,3,2,3,1],[9],[9],[9],[9]],
	o=>[10,[10],[10],[10],[10],[2,5,3],[1,2,3,2,2],[0,3,3,3,1],[0,3,3,3,1],[0,3,3,3,1],[0,3,3,3,1],[1,2,3,2,2],[2,5,3],[10],[10],[10],[10]],
	p=>[10,[10],[10],[10],[10],[0,3,1,3,3],[0,8,2],[0,3,3,3,1],[0,3,3,3,1],[0,3,3,3,1],[0,3,3,3,1],[0,8,2],[0,3,1,3,3],[0,3,7],[0,3,7],[0,3,7],[0,3,7]],
	q=>[9,[9],[9],[9],[9],[2,2,1,3,1],[1,7,1],[0,3,2,3,1],[0,3,2,3,1],[0,3,2,3,1],[0,3,2,3,1],[1,7,1],[2,2,1,3,1],[5,3,1],[5,3,1],[5,3,1],[5,3,1]],
	r=>[8,[8],[8],[8],[8],[0,3,1,3,1],[0,3,1,3,1],[0,7,1],[0,3,5],[0,3,5],[0,3,5],[0,3,5],[0,3,5],[8],[8],[8],[8]],
	s=>[8,[8],[8],[8],[8],[2,3,3],[1,5,2],[0,2,6],[0,6,2],[1,6,1],[4,3,1],[0,6,2],[1,4,3],[8],[8],[8],[8]],
	t=>[7,[3,1,3],[2,2,3],[1,3,3],[1,3,3],[0,5,2],[1,3,3],[1,3,3],[1,3,3],[1,3,3],[1,3,3],[1,5,1],[2,3,2],[7],[7],[7],[7]],
	u=>[9,[9],[9],[9],[9],[0,3,2,3,1],[0,3,2,3,1],[0,3,2,3,1],[0,3,2,3,1],[0,3,2,3,1],[0,3,2,3,1],[0,8,1],[1,3,1,3,1],[9],[9],[9],[9]],
	v=>[9,[9],[9],[9],[9],[0,4,3,2],[1,3,2,2,1],[1,4,1,2,1],[2,3,1,2,1],[2,5,2],[2,5,2],[3,3,3],[3,3,3],[9],[9],[9],[9]],
	w=>[15,[15],[15],[15],[15],[0,4,2,3,3,2,1],[1,3,2,4,1,2,2],[1,4,1,4,1,2,2],[1,4,1,4,1,2,2],[2,8,1,1,3],[2,4,2,4,3],[2,4,2,3,4],[3,3,2,3,4],[15],[15],[15],[15]],
	x=>[10,[10],[10],[10],[10],[0,4,2,3,1],[1,4,1,2,2],[2,5,3],[2,4,4],[3,4,3],[2,5,3],[1,2,1,4,2],[0,3,2,4,1],[10],[10],[10],[10]],
	y=>[10,[10],[10],[10],[10],[0,4,3,2,1],[1,3,2,2,2],[1,4,1,2,2],[2,3,1,1,3],[2,5,3],[3,3,4],[3,3,4],[3,3,4],[4,1,5],[3,2,5],[3,1,6],[2,2,6]],
	z=>[9,[9],[9],[9],[9],[0,8,1],[0,8,1],[3,4,2],[3,3,3],[2,3,4],[1,4,4],[0,8,1],[0,8,1],[9],[9],[9],[9]],
);


my ($query,$key);

$query=new CGI;
$key=($query->param("key") or 'default');

my ($dbh);

$dbh=DBI->connect(SQL_DBI_SOURCE,SQL_USERNAME,SQL_PASSWORD,{AutoCommit=>1}) or die S_SQLCONF;

init_captcha_database() unless(table_exists(SQL_CAPTCHA_TABLE));



my ($ip,$word,$timestamp);

$ip=($ENV{REMOTE_ADDR} or '0.0.0.0');
($word,$timestamp)=get_word($ip,$key);

if(!$word)
{
	$word=make_word();
	$timestamp=time();
	save_word($ip,$key,$word,$timestamp);
}

srand $timestamp;



print $query->header(
	-type=>'image/gif',
#	-expires=>'+'.($timestamp+(CAPTCHA_LIFETIME)-time()),
	-expires=>'now',
);

binmode STDOUT;

make_image($word);

#
# End of main code
#



#
# Code generation
#

sub make_word()
{
#	my $word;
#	for(my $i=0;$i<5;$i++)
#	{
#		$word.=('a','b','c','d','e','f','g','h','i','j','k','l','m','n','o',
#		'p','q','r','s','t','u','v','w','x','y','z')[int(rand(26))];
#	}

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



#
# Finding and saving words
#

sub get_word($$)
{
	my ($ip,$key)=@_;
	my ($sth,$row);

	$sth=$dbh->prepare("SELECT word,timestamp FROM ".SQL_CAPTCHA_TABLE." WHERE ip=? AND pagekey=?;") or die S_SQLFAIL;
	$sth->execute($ip,$key) or die S_SQLFAIL;
	return @{$row} if($row=$sth->fetchrow_arrayref());

	return undef;
}

sub save_word($$$$)
{
	my ($ip,$key,$word,$time)=@_;
	my ($sth);

	$sth=$dbh->prepare("DELETE FROM ".SQL_CAPTCHA_TABLE." WHERE ip=? AND pagekey=?;") or die S_SQLFAIL;
	$sth->execute($ip,$key) or die S_SQLFAIL;

	$sth=$dbh->prepare("INSERT INTO ".SQL_CAPTCHA_TABLE." VALUES(?,?,?,?);") or die S_SQLFAIL;
	$sth->execute($ip,$key,$word,$time) or die S_SQLFAIL;

	trim_captcha_database(); # only cleans up on create - good idea or not?
}



#
# Database utils
#

sub init_captcha_database()
{
	my ($sth);

	$sth=$dbh->do("DROP TABLE ".SQL_CAPTCHA_TABLE.";") if(table_exists(SQL_ADMIN_TABLE));
	$sth=$dbh->prepare("CREATE TABLE ".SQL_CAPTCHA_TABLE." (".
	"ip TEXT,".
	"pagekey TEXT,".
	"word TEXT,".
	"timestamp INTEGER".
#	",PRIMARY KEY(ip,key)".
	");") or die S_SQLFAIL;
	$sth->execute() or die S_SQLFAIL;
}

sub trim_captcha_database()
{
	my ($sth);

	my $mintime=time()-(CAPTCHA_LIFETIME);

	$sth=$dbh->prepare("DELETE FROM ".SQL_CAPTCHA_TABLE." WHERE timestamp<=$mintime;") or die S_SQLFAIL;
	$sth->execute() or die S_SQLFAIL;
}

sub table_exists($)
{
	my ($table)=@_;
	my ($sth);

	return 0 unless($sth=$dbh->prepare("SELECT * FROM ".$table." LIMIT 1;"));
	return 0 unless($sth->execute());
	return 1;
}



#
# Draw the actual image
#

sub make_image($)
{
	my ($word)=@_;
	my ($width,$height);

	$width=string_length($word);
	$height=$font_height+CAPTCHA_SPACING;


	start_128_grey_gif($width,$height);
	draw_string($word);
	end_gif();
}



#
# String drawing
#

sub string_length($)
{
	my @chars=split //,$_[0];
	my ($len);

	foreach my $char (@chars)
	{
		$len+=$font{$char}[0]+(CAPTCHA_SPACING) if($font{$char});
	}

	return $len;
}

sub draw_string($)
{
	my @chars=split //,$_[0];
	my @positions;

	foreach my $char (@chars)
	{
		push @positions,[$font{$char},int(rand(CAPTCHA_SPACING)),int(rand(CAPTCHA_SPACING))] if($font{$char});
	}

	for(my $y=0;$y<$font_height+(CAPTCHA_SPACING);$y++)
	{
		foreach my $pos (@positions)
		{
			my ($glyph,$dx,$dy)=@{$pos};
			my $gy=$y-$dy;

			if($gy<0 or $gy>=$font_height)
			{
				emit_shaded_span($$glyph[0]+(CAPTCHA_SPACING),1);
			}
			else
			{
				my @spans=@{$$glyph[$gy+1]};
				my $white=1;

				emit_shaded_span($dx,1);

				foreach my $span (@spans)
				{
					emit_shaded_span($span,$white);
					$white^=1;
				}

				emit_shaded_span((CAPTCHA_SPACING)-$dx,1);
			}
		}
	}
}

sub emit_shaded_span($$)
{
	my ($width,$white)=@_;
	for(my $i=0;$i<$width;$i++) { emit_shaded_pixel($white); }
}

sub emit_shaded_pixel($)
{
	my ($white)=@_;

	if($white)
	{
#		emit_gif_pixel(int((rand()**(1/CAPTCHA_CLARITY))*128));
		emit_gif_pixel(int((1-rand()**CAPTCHA_CLARITY)*127));
	}
	else
	{
		emit_gif_pixel(int((rand()**CAPTCHA_CLARITY)*128));
#		emit_gif_pixel(int((1-rand()**(1/CAPTCHA_CLARITY))*128));
	}
}



#
# GIF generation
#

my ($pixels,$block);

sub start_128_gif($$@)
{
	my ($width,$height,@palette)=@_;
	$pixels=0;
	$block='';

	print pack("A6 vv CCC","GIF87a",$width,$height,0xa6,0,0);
	print pack('CCC'x128,@palette);
	print pack('CvvvvCC',0x2c,0,0,$width,$height,0x00,0x07);
}

sub start_128_grey_gif($$@)
{
	my ($width,$height,@palette)=@_;
	$pixels=0;
	$block='';

	print pack("A6 vv CCC","GIF87a",$width,$height,0xa6,0,0);
	for(my $i=0;$i<64;$i++) { print pack('CCC',$i*2,$i*2,$i*2); }
	for(my $i=64;$i<128;$i++) { print pack('CCC',$i*2+1,$i*2+1,$i*2+1); }
	print pack('CvvvvCC',0x2c,0,0,$width,$height,0x00,0x07);
}

sub emit_gif_pixel($)
{
	my ($pixel)=@_;

	emit_gif_byte(0x80) if(($pixels%126)==0);
	emit_gif_byte($pixel);
	$pixels++;
}

sub emit_gif_byte($)
{
	my ($byte)=@_;

	$block.=pack('C',$byte);

	if(length($block)==255)
	{
		print pack('C',255);
		print $block;
		$block='';
	}
}

sub end_gif()
{
	emit_gif_byte(0x81);
	emit_gif_byte(0);

	if($block)
	{
		print pack('C',length($block));
		print $block;
	}
	print pack('C',';');
}
