use strict;

BEGIN { require 'futaba_style.pl'; }

#
# Externally called functions
#

sub print_page($$$@)
{
	my ($file,$page,$total,@threads)=@_;

	print_page_header($file);
	print_posting_form($file,0,"");

	print $file '<form name="delform" action="'.get_script_name().'" method="post">';

	foreach my $thread (@threads)
	{
		print_thread($file,0,@{$thread});
	}

	print_deletion_footer($file);

	print $file '</form>';

	print_navi_footer($file,$page,$total);
	print_page_footer($file);

}

sub print_reply($@)
{
	my ($file,@thread)=@_;
	my ($sth,$row);

	print_page_header($file);

	print $file '[<a href="'.expand_filename(HTML_SELF).'">'.S_RETURN.'</a>]';
	print $file '<div class="theader">'.S_POSTING.'</div>';

	print_posting_form($file,$thread[0]{num},"");

	print $file '<form name="delform" action="'.get_script_name().'" method="post">';

	print_thread($file,1,@thread);

	print_deletion_footer($file);

	print $file '</form>';

	print_page_footer($file);
}



#
# Util functions
#

sub print_page_header($)
{
	my ($file)=@_;

	print $file '<html><head>';

	print $file '<title>'.TITLE.'</title>';
	print $file '<meta http-equiv="Content-Type"  content="text/html;charset='.CHARSET.'" />' if(CHARSET);
#	print $file '<meta http-equiv="pragma" content="no-cache">';
	print $file '<link rel="stylesheet" type="text/css" href="'.expand_filename(CSS_FILE).'" title="Standard stylesheet" />';
	print $file '<link rel="shortcut icon" href="'.expand_filename(FAVICON).'" />' if(FAVICON);
	print $file '<script src="'.expand_filename(JS_FILE).'"></script>'; # could be better
	print $file '</head><body>';

	print $file '<div class="adminbar">';
	print $file '[<a href="'.expand_filename(HOME).'" target="_top">'.S_HOME.'</a>]';
	print $file ' [<a href="'.get_secure_script_name().'?action=admin">'.S_ADMIN.'</a>]';
	print $file '</div>';

	print $file '<div class="logo">';
	print $file '<img src="'.expand_filename(TITLEIMG).'" alt="'.TITLE.'" />' if(SHOWTITLEIMG==1);
	print $file '<img src="'.expand_filename(TITLEIMG).'" onclick="this.src=this.src;" alt="'.TITLE.'" />' if(SHOWTITLEIMG==2);
	print $file '<br />' if(SHOWTITLEIMG and SHOWTITLETXT);
	print $file TITLE if(SHOWTITLETXT);
	print $file '</div><hr />';
}

sub print_page_footer($)
{
	my ($file)=@_;

	print $file '<div class="footer">'.S_FOOT.'</div>';
	print $file '</body></html>';
}

sub print_posting_form($$$)
{
	my ($file,$parent,$admin)=@_;
	my ($image_inp,$textonly_inp);

	if($admin) { $image_inp=$textonly_inp=1; }
	else
	{
		if($parent)
		{
			return unless(ALLOW_TEXT_REPLIES or ALLOW_IMAGE_REPLIES);
			$image_inp=1 if(ALLOW_IMAGE_REPLIES);
		}
		else
		{
			return unless(ALLOW_TEXTONLY or ALLOW_IMAGES);
			$image_inp=1 if(ALLOW_IMAGES);
			$textonly_inp=1 if(ALLOW_IMAGES and ALLOW_TEXTONLY);
		}
	}

	print $file '<div class="postarea" align="center">';
	print $file '<form name="postform" action="'.get_script_name().'" method="post" enctype="multipart/form-data">';
	print $file '<input type="hidden" name="action" value="post" />';
	print $file '<input type="hidden" name="parent" value="'.$parent.'" />' if($parent);
	print $file '<input type="hidden" name="admin" value="'.$admin.'" />' if($admin);
	print $file '<table><tbody>';
	print $file '<tr><td class="postblock" align="left">'.S_NAME.'</td><td align="left"><input type="text" name="name" size="28" /></td></tr>';
	print $file '<tr><td class="postblock" align="left">'.S_EMAIL.'</td><td align="left"><input type="text" name="email" size="28" /></td></tr>';
	print $file '<tr><td class="postblock" align="left">'.S_SUBJECT.'</td><td align="left"><input type="text" name="subject" size="35" />';
	print $file ' <input type="submit" value="'.S_SUBMIT.'" /></td></tr>';
	print $file '<tr><td class="postblock" align="left">'.S_COMMENT.'</td><td align="left"><textarea name="comment" cols="48" rows="4"></textarea></td></tr>';

	if($image_inp)
	{
		print $file '<tr><td class="postblock" align="left">'.S_UPLOADFILE.'</td><td><input type="file" name="file" size="35" />';
		print $file ' [<label><input type="checkbox" name="nofile" value="on" />'.S_NOFILE.'</label>]' if($textonly_inp);
		print $file '</td></tr>';
	}
	elsif(!$parent and ALLOW_TEXTONLY)
	{
		print $file '<input type="hidden" name="nofile" value="1" />';
	}

	if(ENABLE_CAPTCHA)
	{
		my $key=get_captcha_key($parent);

		print $file '<tr><td class="postblock" align="left">'.S_CAPTCHA.'</td><td><input type="text" name="captcha" size="10" />';
		print $file ' <img src="'.expand_filename(CAPTCHA_SCRIPT).'?key='.$key.'" />';
		print $file '</td></tr>';
	}

#	print $file '<tr><td class="postblock" align="left">'.S_DELPASS.'</td><td align="left"><input type="password" name="password" size="8" maxlength="8" value="'.$c_password.'" /> '.S_DELEXPL2.'</td></tr>';
	print $file '<tr><td class="postblock" align="left">'.S_DELPASS.'</td><td align="left"><input type="password" name="password" size="8" maxlength="8" /> '.S_DELEXPL.'</td></tr>';
	print $file '<tr><td colspan="2">';
	print $file '<div align="left" class="rules">'.S_RULES.'</div></td></tr>';
	print $file '</tbody></table></form></div><hr />';
	print $file '<script>with(document.postform) {name.value=get_cookie("name"); email.value=get_cookie("email"); password.value=get_password("password"); }</script>';
}

sub print_thread($$@)
{
	my ($file,$threadview,@thread)=@_;
	my ($parent,$replies);

 	# remove parent post from start of thread 
 	$parent=shift @thread;

	# display image
	print_image($file,$parent,0) if($$parent{image});

	print $file '<table cellspacing="0"><tbody><tr><td>';

	# display the original thread comment
	print_comment_header($file,$parent,!$threadview,1);
	print $file '<blockquote>'.$$parent{comment}.'</blockquote><br />';

	# check to see if we should abbreviate the thread
	$replies=scalar(@thread);

	if($replies>REPLIES_PER_THREAD and !$threadview)
	{
		my $omit=$replies-(REPLIES_PER_THREAD);
		my $images=0;

		# drop the articles at the beginning of the thread
		for(my $i=0;$i<$omit;$i++)
		{
			my $res=shift @thread;
			$images++ if($$res{image});
		}

		if($images)
		{
			print $file '<span class="omittedposts">'.(sprintf S_ABBRIMG,$omit,$images).'</span>';
		}
		else
		{
			print $file '<span class="omittedposts">'.(sprintf S_ABBR,$omit).'</span>';
		}
	}

	print $file '</tr></td>';

	# display replies

	foreach my $res (@thread)
	{
		print $file '<tr><td style="background:#e0c0b0;">';

		print_comment_header($file,$res,0,0);

		print $file '</td></tr><tr><td class="reply">';

		if($$res{image})
		{
			print $file '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;';
			print_image($file,$res,!$threadview);
		}

		print $file '<blockquote>'.$$res{comment}.'</blockquote>';

		print $file '</td></tr>';

		print $file '<tr><td style="font-size:0.3em;">&nbsp;</td></tr>';
	}

	print $file '</tbody></table><br clear="left" /><hr />';
}

sub print_comment_header($$$$)
{
	my ($file,$res,$reply,$toplevel)=@_;
	my ($titleclass,$nameclass);

	$titleclass=$toplevel?"filetitle":"replytitle";
	$nameclass=$toplevel?"postername":"commentpostername";

	print $file '<a name="'.$$res{num}.'"></a>';
	print $file '<label><input type="checkbox" name="delete" value="'.$$res{num}.'" />';
	print $file '<span class="'.$titleclass.'">'.$$res{subject}.'</span>';
	print $file ' <span class="'.$nameclass.'">';
	print $file '<a href="mailto:'.$$res{email}.'">' if($$res{email});
	print $file $$res{name};
	print $file '</a>' if($$res{email});
	print $file '</span>';

	if($$res{trip})
	{
		print $file '<span class="postertrip">';
		print $file '<a href="mailto:'.$$res{email}.'">' if($$res{email});
		print $file TRIPKEY.$$res{trip};
		print $file '</a>' if($$res{email});
		print $file '</span>';
	}

	print $file ' '.$$res{date};
	# calc and show ID
	print $file ' No.'.$$res{num}.'</label>&nbsp;';
	print $file ' [<a href="'.get_reply_link($$res{num}).'">'.S_REPLY.'</a>]' if($reply);
}

sub print_image($$$)
{
	my ($file,$res,$hidden)=@_;
 	$$res{image}=~m!([^/]+)$!;
 	my ($imagename)=$1;

	$hidden=0 unless(HIDE_IMAGE_REPLIES);

	print $file '<span class="filesize">'.S_PICNAME.'<a target="_blank" href="'.expand_filename($$res{image}).'">'.$imagename.'</a>';
	print $file '-('.$$res{size}.' B, '.$$res{width}.'x'.$$res{height}.')</span>';
	print $file ' <span class="thumbnailmsg">'.S_THUMB.'</span>' unless($hidden);
	print $file ' <span class="thumbnailmsg">'.S_HIDDEN.'</span>' if($hidden);
	print $file '<br /><a target="_blank" href="'.expand_filename($$res{image}).'">';

	unless($hidden)
	{
		if($$res{thumbnail})
		{
			print $file '<img src="'.expand_filename($$res{thumbnail}).'" border="0" align="left"';
			print $file ' width="'.$$res{tn_width}.'" height="'.$$res{tn_height}.'" hspace="20" alt="'.$$res{size}.'">';
		}
		else
		{
			print $file '<div hspace="20" style="float:left;text-align:center;padding:20px;">'.S_NOTHUMB.'</div>';
		}
	}
	print $file '</a>';
}

sub print_deletion_footer($)
{
	my ($file)=@_;

	print $file '<table align="right"><tbody><tr><td align="center" nowrap="nowrap">';
	print $file '<input type="hidden" name="action" value="delete" />';
	print $file S_REPDEL.'[<label><input type="checkbox" name="fileonly" value="on" />'.S_DELPICONLY.'</label>]<br />';
#	print $file S_DELKEY.'<input type="password" name="password" value="'.$c_password.'" maxlength="8" size="8" />';
	print $file S_DELKEY.'<input type="password" name="password" maxlength="8" size="8" />';
	print $file '<input value="'.S_DELETE.'" type="submit"></td></tr></tbody></table></form>';
	print $file '<script>document.delform.password.value=get_cookie("password");</script>';
}

sub print_navi_footer($$$)
{
	my ($file,$page,$total)=@_;
	my (@pages,$i);

	@pages=get_page_links($total);

	print $file '<table border="1"><tbody><tr><td>';

	if($page==0)
	{ print $file S_FIRSTPG; }
	else
	{ print $file '<form method="get" action='.$pages[$page-1].'><input value="'.S_PREV.'" type="submit" /></form>'; }

	print $file '</td><td>';

	for($i=0;$i<$total;$i++)
	{
		if($i==$page)
		{ print $file '['.$i.'] ' }
		else
		{ print $file '[<a href="'.$pages[$i].'">'.$i.'</a>] '; }
	}

	print $file '</td><td>';

	if($page==$total-1)
	{ print $file S_LASTPG; }
	else
	{ print $file '<form method="get" action='.$pages[$page+1].'><input value="'.S_NEXT.'" type="submit" /></form>'; }

	print $file '</td></tr></tbody></table><br clear="all">';
}

1;
