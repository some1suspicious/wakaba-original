#!/usr/bin/perl

use CGI::Carp qw(fatalsToBrowser);

use strict;

use CGI;

use lib '.';
BEGIN { require 'config.pl'; }
BEGIN { require 'oekaki_config.pl'; }
BEGIN { require 'oekaki_strings_e.pl'; }



my $query=new CGI;

my $oek_painter=$query->param("oek_painter");
my $oek_x=$query->param("oek_x");
my $oek_y=$query->param("oek_y");
my $oek_parent=$query->param("oek_parent");
my $oek_src=$query->param("oek_src");
my $ip=$ENV{REMOTE_ADDR};

make_error(S_HAXORING) if($oek_x=~/[^0-9]/ or $oek_y=~/[^0-9]/ or $oek_parent=~/[^0-9]/);
make_error(S_HAXORING) if($oek_src=~m![^0-9a-zA-Z/]!);
make_error(S_OEKTOOBIG) if($oek_x>OEKAKI_MAX_X or $oek_y>OEKAKI_MAX_Y);
make_error(S_OEKTOOSMALL) if($oek_x<OEKAKI_MIN_X or $oek_y<OEKAKI_MIN_Y);

if($oek_painter=~/shii/)
{
	my $mode;
	$mode="pro" if($oek_painter=~/pro/);

	if($oek_painter=~/selfy/) { print <<HTML_SELFY;
Content-Type: text/html; charset=Shift_JIS

<html>
<head>
<link rel="stylesheet" type="text/css" href="oekaki.css">
</head>
<body>
<script type="text/javascript" src="palette_selfy.js"></script>

<table class="nospace" width="100%" height="100%"><tbody><tr>
<td width="100%">
<applet code="c.ShiPainter.class" name="paintbbs" archive="spainter_all.jar" width="100%" height="100%">
<param name="image_width" value="$oek_x" />
<param name="image_height" value="$oek_y" />
<param name="dir_resource" value="./" />
<param name="tt.zip" value="tt_def.zip" />
<param name="res.zip" value="res.zip" />
<param name="tools" value="$mode" />
<param name="layer_count" value="3" />
<param name="url_save" value="getpic.pl" />
<param name="url_exit" value="finish.pl?oek_parent=$oek_parent&oek_ip=$ip" />
<param name="send_header" value="$ip" />
</applet>
</td>
<td valign="top">
<script>palette_selfy();</script>
</td>
</tr></tbody></table>
</body>
</html>
HTML_SELFY
	} else { print <<HTML_NORM;
Content-Type: text/html

<html>
<head>
<link rel="stylesheet" type="text/css" href="oekaki.css">
</head>
<body>
<applet code="c.ShiPainter.class" name="paintbbs" archive="spainter_all.jar" width="100%" height="100%">
<param name="image_width" value="$oek_x" />
<param name="image_height" value="$oek_y" />
<param name="dir_resource" value="./" />
<param name="tt.zip" value="tt_def.zip" />
<param name="res.zip" value="res.zip" />
<param name="tools" value="$mode" />
<param name="layer_count" value="3" />
<param name="url_save" value="getpic.pl" />
<param name="url_exit" value="finish.pl?oek_parent=$oek_parent&oek_ip=$ip" />
<param name="send_header" value="$ip" />
</applet>
</body>
</html>
HTML_NORM
	}
}
else
{
	make_error(S_OEKUNKNOWN);
}




sub make_error($)
{
	my ($error)=@_;
	my $css=CSS_FILE;

	print <<ERROR;
Status: 500 $error
Content-Type: text/html

<html>
<head>
<title>$error</title>
<link rel="stylesheet" type="text/css" href="$css" title="Standard stylesheet" />
</head>
<body>
<div style="text-align: center; width=100%; font-size: 2em;"><br />$error
<br /><br /><a href="$ENV{HTTP_REFERER}">Return</a>
</div>
</body>
</html>
ERROR

	exit;
}
