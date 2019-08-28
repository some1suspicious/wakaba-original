#!/usr/bin/perl

use CGI::Carp qw(fatalsToBrowser);

use strict;

use CGI;

use lib '.';
BEGIN { require 'config.pl'; }
BEGIN { require 'oekaki_config.pl'; }
BEGIN { require 'oekaki_strings_e.pl'; }



my ($c_password,$c_name,$c_email);
my ($self_path);

my $query=new CGI;

my $oek_painter=$query->param("oek_painter");
my $oek_x=$query->param("oek_x");
my $oek_y=$query->param("oek_y");

my $mode;

if ($oek_x > OEKAKI_MAX_X || $oek_y > OEKAKI_MAX_Y) 
{
	make_error(S_OEKTOOBIG);
}

if ($oek_x < OEKAKI_MIN_X || $oek_y < OEKAKI_MIN_Y) 
{
	die S_OEKTOOSMALL;
}

if ($oek_painter eq "shii_norm")
{
	$mode = "";
}
elsif ($oek_painter eq "shii_pro")
{ 
	$mode = "pro";
}
else
{
	make_error(S_OEKUNKNOWN);
}

print <<HTML;
Content-Type: text/html

<html>
<body>
<applet code="c.ShiPainter.class" name="paintbbs" archive="spainter_all.jar" width="100%" height="100%">
<param name="image_width" value="$oek_x">
<param name="image_height" value="$oek_y">
<param name="dir_resource" value="./">
<param name="tt.zip" value="tt_def.zip">
<param name="res.zip" value="res.zip">
<param name="tools" value="$mode">
<param name="layer_count" value="3">
<param name="url_save" value="getpic.pl">
<param name="url_exit" value="finish.pl">
</applet>
</body>
</html>
HTML



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
