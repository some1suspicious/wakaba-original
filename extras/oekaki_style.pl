use strict;

use strict;

BEGIN { require 'oekaki_config.pl'; }
BEGIN { require 'oekaki_strings_en.pl'; }
BEGIN { require 'futaba_style.pl'; }
BEGIN { require 'wakautils.pl'; }

BEGIN { $SIG{'__WARN__'} = sub {} } # kill warnings when redefining PAGE_TEMPLATE


use constant PAGE_TEMPLATE => compile_template(NORMAL_HEAD_INCLUDE.q{

<if $thread>
	[<a href="<var expand_filename(HTML_SELF)>"><const S_RETURN></a>]
	<div class="theader"><const S_POSTING></div>
</if>

<if $postform>
	<if $thread><hr /></if>
	<div align="center">
	<form action="<var expand_filename('paint.pl')>" method="get">
	<if $thread><input type="hidden" name="oek_parent" value="<var $thread>" /></if>

	<const S_OEKPAINT>
	<select name="oek_painter">

	<loop S_OEKPAINTERS>
		<if $painter eq OEKAKI_DEFAULT_PAINTER>
		<option value="<var $painter>" selected="selected"><var $name></option>
		</if>
		<if $painter ne OEKAKI_DEFAULT_PAINTER>
		<option value="<var $painter>"><var $name></option>
		</if>
	</loop>
	</select>

	<const S_OEKX><input type="text" name="oek_x" size="3" value="<const OEKAKI_DEFAULT_X>" />
	<const S_OEKY><input type="text" name="oek_y" size="3" value="<const OEKAKI_DEFAULT_Y>" />

	<if OEKAKI_ENABLE_MODIFY and $thread>
		<const S_OEKSOURCE>
		<select name="oek_src">
		<option value=""><const S_OEKNEW></option>

		<loop $threads>
			<loop $posts>
				<if $image>
					<option value="<var $image>"><var sprintf S_OEKMODIFY,$num></option>
				</if>
			</loop>
		</loop>
		</select>
	</if>

	<input type="submit" value="<const S_OEKSUBMIT>" />
	</form>
	</div><hr />

	<div class="postarea">
	<form name="postform" action="<var $self>" method="post" enctype="multipart/form-data">

	<input type="hidden" name="task" value="post" />
	<if $thread><input type="hidden" name="parent" value="<var $thread>" /></if>
	<if !$image_inp and !$thread and ALLOW_TEXTONLY>
		<input type="hidden" name="nofile" value="1" />
	</if>

	<table><tbody>
	<tr><td class="postblock"><const S_NAME></td><td><input type="text" name="name" size="28" /></td></tr>
	<tr><td class="postblock"><const S_EMAIL></td><td><input type="text" name="email" size="28" /></td></tr>
	<tr><td class="postblock"><const S_SUBJECT></td><td><input type="text" name="subject" size="35" />
	<input type="submit" value="<const S_SUBMIT>" /></td></tr>
	<tr><td class="postblock"><const S_COMMENT></td><td><textarea name="comment" cols="48" rows="4"></textarea></td></tr>

	<if $image_inp>
		<tr><td class="postblock"><const S_UPLOADFILE></td><td><input type="file" name="file" size="35" />
		<if $textonly_inp>[<label><input type="checkbox" name="nofile" value="on" /><const S_NOFILE> ]</label></if>
		</td></tr>
	</if>

	<if ENABLE_CAPTCHA and !$admin>
		<tr><td class="postblock"><const S_CAPTCHA></td><td><input type="text" name="captcha" size="10" />
		<img alt="" src="<var expand_filename(CAPTCHA_SCRIPT)>?key=<var get_captcha_key($thread)>&amp;dummy=<var $dummy>" />
		</td></tr>
	</if>

	<tr><td class="postblock"><const S_DELPASS></td><td><input type="password" name="password" size="8" /> <const S_DELEXPL></td></tr>
	<tr><td colspan="2">
	<div class="rules">}.include("include/rules.html").q{</div></td></tr>
	</tbody></table></form></div>
	<script type="text/javascript">set_inputs(document.forms.postform)</script>
</if>

<hr />
<form name="delform" action="<var $self>" method="post">

<loop $threads>
	<loop $posts>
		<if !$parent>
			<if $image>
				<span class="filesize"><const S_PICNAME><a target="_blank" href="<var expand_filename($image)>"><var get_filename($image)></a>
				-(<em><var $size> B, <var $width>x<var $height></em>)</span>
				<span class="thumbnailmsg"><const S_THUMB></span><br />

				<if $thumbnail>
					<a target="_blank" href="<var expand_filename($image)>">
					<img src="<var expand_filename($thumbnail)>" width="<var $tn_width>" height="<var $tn_height>" alt="<var $size>" class="thumb" /></a>
				</if>
				<if !$thumbnail>
					<div class="nothumb"><a target="_blank" href="<var expand_filename($image)>"><const S_NOTHUMB></a></div>
				</if>
			</if>

			<a name="<var $num>"></a>
			<label><input type="checkbox" name="delete" value="<var $num>" />
			<span class="filetitle"><var $subject></span>
			<if $email><span class="postername"><a href="<var $email>"><var $name></a></span><if $trip><span class="postertrip"><a href="<var $email>"><var $trip></a></span></if></if>
			<if !$email><span class="postername"><var $name></span><if $trip><span class="postertrip"><var $trip></span></if></if>
			<var $date></label>
			<span class="reflink">
			<if !$thread><a href="<var get_reply_link($num,0)>#i<var $num>">No.<var $num></a></if>
			<if $thread><a href="javascript:insert('&gt;&gt;<var $num>')">No.<var $num></a></if>
			</span>&nbsp;
			<if !$thread>[<a href="<var get_reply_link($num,0)>"><const S_REPLY></a>]</if>

			<blockquote>
			<var $comment>
			<if $abbrev><div class="abbrev"><var sprintf(S_ABBRTEXT,get_reply_link($num,$parent))></div></if>
			</blockquote>

			<if $omit>
				<span class="omittedposts">
				<if $omitimages><var sprintf S_ABBRIMG,$omit,$omitimages></if>
				<if !$omitimages><var sprintf S_ABBR,$omit></if>
				</span>
			</if>
		</if>
		<if $parent>
			<table><tbody><tr><td class="doubledash">&gt;&gt;</td>
			<td class="reply" id="reply<var $num>">

			<a name="<var $num>"></a>
			<label><input type="checkbox" name="delete" value="<var $num>" />
			<span class="replytitle"><var $subject></span>
			<if $email><span class="commentpostername"><a href="<var $email>"><var $name></a></span><if $trip><span class="postertrip"><a href="<var $email>"><var $trip></a></span></if></if>
			<if !$email><span class="commentpostername"><var $name></span><if $trip><span class="postertrip"><var $trip></span></if></if>
			<var $date></label>
			<span class="reflink">
			<if !$thread><a href="<var get_reply_link($parent,0)>#i<var $num>">No.<var $num></a></if>
			<if $thread><a href="javascript:insert('&gt;&gt;<var $num>')">No.<var $num></a></if>
			</span>&nbsp;

			<if $image>
				<br />
				<span class="filesize"><const S_PICNAME><a target="_blank" href="<var expand_filename($image)>"><var get_filename($image)></a>
				-(<em><var $size> B, <var $width>x<var $height></em>)</span>
				<span class="thumbnailmsg"><const S_THUMB></span><br />

				<if $thumbnail>
					<a target="_blank" href="<var expand_filename($image)>">
					<img src="<var expand_filename($thumbnail)>" width="<var $tn_width>" height="<var $tn_height>" alt="<var $size>" class="thumb" /></a>
				</if>
				<if !$thumbnail>
					<div class="nothumb"><a target="_blank" href="<var expand_filename($image)>"><const S_NOTHUMB></a></div>
				</if>
			</if>

			<blockquote>
			<var $comment>
			<if $abbrev><div class="abbrev"><var sprintf(S_ABBRTEXT,get_reply_link($num,$parent))></div></if>
			</blockquote>

			</td></tr></tbody></table>
		</if>
	</loop>
	<br clear="left" /><hr />
</loop>

<table class="userdelete"><tbody><tr><td>
<input type="hidden" name="task" value="delete" />
<const S_REPDEL>[<label><input type="checkbox" name="fileonly" value="on" /><const S_DELPICONLY></label>]<br />
<const S_DELKEY><input type="password" name="password" size="8" />
<input value="<const S_DELETE>" type="submit" /></td></tr></tbody></table>
</form>

<if !$thread>
	<table border="1"><tbody><tr><td>

	<if $prevpage><form method="get" action="<var $prevpage>"><input value="<const S_PREV>" type="submit" /></form></if>
	<if !$prevpage><const S_FIRSTPG></if>

	</td><td>

	<loop $pages>
		<if $filename>[<a href="<var $filename>"><var $page></a>]</if>
		<if !$filename>[<var $page>]</if>
	</loop>

	</td><td>

	<if $nextpage><form method="get" action="<var $nextpage>"><input value="<const S_NEXT>" type="submit" /></form></if>
	<if !$nextpage><const S_LASTPG></if>

	</td></tr></tbody></table><br clear="all" />
</if>

}.NORMAL_FOOT_INCLUDE);

BEGIN { undef $SIG{'__WARN__'} } # re-enable warnings



# terrible quirks mode code
use constant OEKAKI_PAINT_TEMPLATE => compile_template(q{

<html>
<head>
<style type="text/css">
body { background: #9999BB; font-family: sans-serif; }
input,textarea { background-color:#CFCFFF; font-size: small; }
table.nospace { border-collapse:collapse; }
table.nospace tr td { margin:0px; } 
.menu { background-color:#CFCFFF; border: 1px solid #666666; padding: 2px; margin-bottom: 2px; }
</style>
</head><body>

<script type="text/javascript" src="palette_selfy.js"></script>
<table class="nospace" width="100%" height="100%"><tbody><tr>
<td width="100%">
<applet code="c.ShiPainter.class" name="paintbbs" archive="spainter_all.jar" width="100%" height="100%">
<param name="image_width" value="<var $oek_x>" />
<param name="image_height" value="<var $oek_y>" />
<param name="image_canvas" value="<var $oek_src>" />
<param name="dir_resource" value="./" />
<param name="tt.zip" value="tt_def.zip" />
<param name="res.zip" value="res.zip" />
<param name="tools" value="<var $mode>" />
<param name="layer_count" value="3" />
<param name="url_save" value="getpic.pl" />
<param name="url_exit" value="finish.pl?oek_parent=<var $oek_parent>&amp;oek_ip=<var $ip>&amp;srcinfo=<var $time>,<var $oek_painter>,<var $oek_src>" />
<param name="send_header" value="<var $ip>" />
</applet>
</td>
<if $selfy>
	<td valign="top">
	<script>palette_selfy();</script>
	</td>
</if>
</tr></tbody></table>
</body>
</html>
});


use constant OEKAKI_INFO_TEMPLATE => compile_template(q{
<p><small><strong>
Oekaki post</strong> (Time: <var $time>, Painter: <var $painter><if $source>, Source: <a href="<var $path><var $source>"><var $source></a></if>)
</small></p>
});


use constant OEKAKI_FINISH_TEMPLATE => compile_template(NORMAL_HEAD_INCLUDE.q{

[<a href="<var expand_filename(HTML_SELF)>"><const S_RETURN></a>]
<div class="theader"><const S_POSTING></div>

<div class="postarea">
<form name="postform" action="<var $self>" method="post" enctype="multipart/form-data">
<input type="hidden" name="task" value="post" />
<input type="hidden" name="oek_ip" value="<var $oek_ip>" />
<input type="hidden" name="srcinfo" value="<var $srcinfo>" />
<table><tbody>
<tr><td class="postblock"><const S_NAME></td><td><input type="text" name="name" size="28" /></td></tr>
<tr><td class="postblock"><const S_EMAIL></td><td><input type="text" name="email" size="28" /></td></tr>
<tr><td class="postblock"><const S_SUBJECT></td><td><input type="text" name="subject" size="35" />
<input type="submit" value="<const S_SUBMIT>" /></td></tr>
<tr><td class="postblock"><const S_COMMENT></td><td><textarea name="comment" cols="48" rows="4"></textarea></td></tr>

<if $image_inp>
	<tr><td class="postblock"><const S_UPLOADFILE></td><td><input type="file" name="file" size="35" />
	<if $textonly_inp>[<label><input type="checkbox" name="nofile" value="on" /><const S_NOFILE></label></if>
	</td></tr>
</if>

<if ENABLE_CAPTCHA and !$admin>
	<tr><td class="postblock"><const S_CAPTCHA></td><td><input type="text" name="captcha" size="10" />
	<img alt="" src="<var expand_filename(CAPTCHA_SCRIPT)>?key=<var get_captcha_key($thread)>&amp;dummy=<var $dummy>" />
	</td></tr>
</if>

<tr><td class="postblock"><const S_DELPASS></td><td><input type="password" name="password" size="8" /> <const S_DELEXPL></td></tr>

<if $oek_parent>
	<input type="hidden" name="parent" value="<var $oek_parent>" />
	<tr><td class="postblock"><const S_OEKIMGREPLY></td>
	<td><var sprintf(S_OEKREPEXPL,expand_filename(RES_DIR.$oek_parent.PAGE_EXT),$oek_parent)></td></tr>
</if>

<tr><td colspan="2">
<div class="rules">}.include("include/rules.html").q{</div></td></tr>
</tbody></table></form></div>
<script type="text/javascript">set_inputs(document.forms.postform)</script>

<hr />

<div align="center">
<img src="<var expand_filename($tmpname)>" />
<var $decodedinfo>
</div>

<hr />

}.NORMAL_FOOT_INCLUDE);








sub print_paasdsage($$$$$)
{
	my ($file,$tmpname,$oek_parent,$oek_ip,$srcinfo)=@_;

	print $file '<html><head>';

	print $file '<title>'.TITLE.'</title>';
	print $file '<meta http-equiv="Content-Type"  content="text/html;charset='.CHARSET.'" />' if(CHARSET);
	print $file '<link rel="stylesheet" type="text/css" href="'.expand_filename(CSS_FILE).'" title="Standard stylesheet" />';
	print $file '<link rel="shortcut icon" href="'.expand_filename(FAVICON).'" />' if(FAVICON);
	print $file '<script src="'.expand_filename(JS_FILE).'"></script>'; # could be better
	print $file '</head><body>';

#	print $file S_HEAD;

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
#	print $file '<div align="left" class="rules">'.S_RULES.'</div></td></tr>';
	print $file '</tbody></table></form></div><hr />';
	print $file '<script>with(document.postform) {if(!name.value) name.value=get_cookie("name"); if(!email.value) email.value=get_cookie("email"); if(!password.value) password.value=get_password("password"); }</script>';

	print $file '<div align="center">';
	print $file '<img src="'.expand_filename($tmpname).'">';
	print INFO_TEMPLATE->(decode_srcinfo($srcinfo));
	print $file '</div>';

	print $file '<hr />';
#	print $file S_FOOT;
	print $file '</body></html>';
}









1;

