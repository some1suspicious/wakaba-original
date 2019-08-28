use strict;

use constant HEAD_TEMPLATE => q{

<html><head>
<title><var TITLE></title>
<meta http-equiv="Content-Type"  content="text/html;charset=utf-8" />
<link rel="stylesheet" type="text/css" href="wakaba.css" title="Standard stylesheet" />
<!-- link rel="shortcut icon" href="wakaba.ico" /-->
<script src="wakaba.js"></script>
</head><body>


<div class="adminbar">[<a href=".." target="_top">Home</a>]</div>

<div class="logo">
<if SHOWTITLEIMG==1><img src="<var TITLEIMG>" alt="<var TITLE>" /></if>
<if SHOWTITLEIMG==2><img src="<var TITLEIMG>" onclick="this.src=this.src;" alt="<var TITLE>" /></if>
<if SHOWTITLEIMG and SHOWTITLETXT><br /></if>
<if SHOWTITLETXT><var TITLE></if>
</div><hr />

<if $thread>
[<a href="<var HTML_SELF>">Return</a>]
<div class="theader">Posting mode: Reply</div>
</if>

<div class="postarea" align="center">
<form name="postform" action="<var $self>" method="post" enctype="multipart/form-data">
<input type="hidden" name="action" value="post" />
<if $thread><input type="hidden" name="parent" value="<var $thread>" /></if>
<table><tbody>
<tr><td class="postblock" align="left">Name</td><td align="left"><input type="text" name="name" size="28" /></td></tr>
<tr><td class="postblock" align="left">E-mail</td><td align="left"><input type="text" name="email" size="28" /></td></tr>
<tr><td class="postblock" align="left">Subject</td><td align="left"><input type="text" name="subject" size="35" />
 <input type="submit" value="Submit" /></td></tr>
<tr><td class="postblock" align="left">Comment</td><td align="left"><textarea name="comment" cols="48" rows="4"></textarea></td></tr>

<tr><td class="postblock" align="left">File</td><td><input type="file" name="file" size="35" />
<if !$thread> [<label><input type="checkbox" name="nofile" value="on" />No File</label>]</if>
</td></tr>

<if ENABLE_CAPTCHA>
<tr><td class="postblock" align="left">Verification</td><td><input type="text" name="captcha" size="10" />
<script>var key=make_password(); document.write('<img src="captcha.pl?key='+key+'" /><input type="hidden" name="key" value="'+key+'" />');</script>
</td></tr>
</if>

<tr><td class="postblock" align="left">Password</td><td align="left"><input type="password" name="password" size="8" maxlength="8" />
(Password used for file deletion)</td></tr>
<tr><td colspan="2">
<div align="left" class="rules"><ul>
<li>Supported file types are: GIF, JPG, PNG</li>
<li>Maximum file size allowed is <var MAX_KB> KB.</li>
<li>Images greater than <var MAX_W>x<var MAX_H> pixels will be thumbnailed.</li>
</ul></div></td></tr>
</tbody></table></form></div><hr />
<script>with(document.postform) {name.value=get_cookie("name"); email.value=get_cookie("email"); password.value=get_password("password"); }</script>
<var $crap>
<form name="delform" action="<var $self>" method="post">
};



use constant FOOT_TEMPLATE => q{

<if !$thread>
<table border="1"><tbody><tr><td>
<if !$prev><if 1></if>[Previous]</if>
<if $prev>[<a href="<var $prev>">&lt;&lt; Previous</a>]</if>
<loop $pages>
<if $curr>[<var $page>]</if>
<if !$curr>[<a href="<var $link>"><var $page></a>]</if>
</loop>
<if !$next>[Next]</if>
<if $next>[<a href="<var $next>">Next &gt;&gt;</a>]</if>
</td></tr></tbody></table><br clear="all">
</if>

<if $thread>
<br clear="left" /><hr />
</if>

<table align="right"><tbody><tr><td align="center" nowrap="nowrap">
<input type="hidden" name="action" value="delete" />
Delete Post [<label><input type="checkbox" name="fileonly" value="on" />File Only</label>]<br />
Password <input type="password" name="password" maxlength="32" size="8" />
<input value="Delete" type="submit"></td></tr></tbody></table></form>
<script>document.delform.password.value=get_cookie("password");</script>
</form>

<div class="footer">
- <a href="http://wakaba.c3.cx/">wakaba-0</a>
+ <a href="http://www.2chan.net/">futaba</a>
+ <a href="http://www.1chan.net/futallaby/">futallaby</a> -
</div>
</body></html>
};



use constant THREAD_TEMPLATE => q{

<if $image>

<span class="filesize">
File: <a target="_blank" href="<var $image>"><var $image=~m!([^/]+)$!; $1></a>-(<em><var $size> B, <var $width>x<var $height></em>)
</span>
<if 1><span class="thumbnailmsg">Thumbnail displayed, click image for full size.</span></if>
<if 0><span class="thumbnailmsg">Image reply hidden, click name for full image.</span></if>
<br />
<a target="_blank" href="<var $image>">
<if $thumbnail><img src="<var $thumbnail>" border="0" align="left" width="<var $tn_width>" height="<var $tn_height>" hspace="20" alt="<var $size>"></if>
<if !$thumbnail><div hspace="20" style="float:left;text-align:center;padding:20px;">No<br />thumbnail</div></if>
</a>

</if>

<label><input type="checkbox" name="delete" value="<var $thread>,1" />
<span class="filetitle"><var $subject></span>
<span class="postername">
<if $email><a href="mailto:<var $email>"></if>
<var $name>
<if $email></a></if>
</span>

<if $trip>
<span class="postertrip">
<if $email><a href="mailto:<var $email>"></if>
<var TRIPKEY><var $trip>
<if $email></a></if>
</span>
</if>

<var $date>
No.<span class="post_num">1</span></label>

<blockquote><var $comment></blockquote>
};



use constant REPLY_TEMPLATE => q{

<table><tbody><tr><td class="doubledash">&gt;&gt;</td>
<td class="reply">

<label><input type="checkbox" name="delete" value="<var $parent>,<var $num>" />
<span class="replytitle"><var $subject></span>
<span class="commentpostername">
<if $email><a href="mailto:<var $email>"></if>
<var $name>
<if $email></a></if>
</span>

<if $trip>
<span class="postertrip">
<if $email><a href="mailto:<var $email>"></if>
<var TRIPKEY><var $trip>
<if $email></a></if>
</span>
</if>

<var $date>
No.<span class="post_num"><var $num></span></label>


<if $image>

<br />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<span class="filesize">
File: <a target="_blank" href="<var $image>"><var $image=~m!([^/]+)$!; $1></a>-(<em><var $size> B, <var $width>x<var $height></em>)
</span>
<if 1><span class="thumbnailmsg">Thumbnail displayed, click image for full size.</span></if>
<if 0><span class="thumbnailmsg">Image reply hidden, click name for full image.</span></if>
<br />
<a target="_blank" href="<var $image>">
<if $thumbnail><img src="<var $thumbnail>" border="0" align="left" width="<var $tn_width>" height="<var $tn_height>" hspace="20" alt="<var $size>"></if>
<if !$thumbnail><div hspace="20" style="float:left;text-align:center;padding:20px;">No<br />thumbnail</div></if>
</a>

</if>

<blockquote><var $comment></blockquote>
</td></tr></tbody></table>
};



use constant SUMMARY_TEMPLATE => q{

<div style="float:right; font-size: large;">[<a href="<var $page>">Reply</a>]</div>
<var $threadstart>

<if $omit>
<span class="omittedposts">
<if $images><var $omit> post<if $omit!=1>s</if> and <var $images> image<if $images!=1>s</if> omitted. Click Reply to view.</if>
<if !$images><var $omit> post<if $omit!=1>s</if> omitted. Click Reply to view.</if>
</span>
</if>

<loop $replies>
<var $reply>
</loop>

<br clear="left" /><hr />
};


use constant S_WEEKDAYS => ('Sun','Mon','Tue','Wed','Thu','Fri','Sat');				# Defines abbreviated weekday names.
use constant S_TOOBIG => 'This image is too large!  Upload something smaller!';
use constant S_TOOBIGORNONE => 'Either this image is too big or there is no image at all.  Yeah.';
use constant S_REPORTERR => 'Error: Cannot find reply.';						# Returns error when a reply (res) cannot be found
use constant S_BADCAPTCHA => 'Error: Wrong verification code entered.';					# Returns error when the captcha is wrong
use constant S_BADFORMAT => 'Error: File format not supported.';					# Returns error when the file is not in a supported format.
use constant S_UNJUST => 'Error: Unjust POST.';								# Returns error on an unjust POST - prevents floodbots or ways not using POST method?
use constant S_NOPIC => 'Error: No file selected.';							# Returns error for no file selected and override unchecked
use constant S_NOTEXT => 'Error: No text entered.';							# Returns error for no text entered in to subject/comment
use constant S_TOOLONG => 'Error: Field too long.';							# Returns error for too many characters in a given field
use constant S_UNUSUAL => 'Error: Abnormal reply.';							# Returns error for abnormal reply? (this is a mystery!)
use constant S_PROXY => 'Error: Proxy detected on port %d.';						# Returns error for proxy detection.
use constant S_DUPE => 'Error: Duplicate file entry detected.';						# Returns error when an md5 checksum already exists.
use constant S_NOTHREADERR => 'Error: Thread specified does not exist.';				# Returns error when a non-existant thread is accessed
use constant S_BADDELPASS => 'Error: Password incorrect.';						# Returns error for wrong password (when user tries to delete file)
use constant S_NOTWRITE => 'Error: Cannot write to directory.';						# Returns error when the script cannot write to the directory, the chmod (777) is wrong

1;
