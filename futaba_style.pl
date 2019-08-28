use strict;

#
# Externally called functions
#

sub print_page($$$@)
{
	my ($file,$page,$total,@threads)=@_;

	print_page_header($file);
	print_posting_form($file,0,"","");

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

	print_posting_form($file,$thread[0]{num},"",$thread[$#thread]{num});

	print $file '<form name="delform" action="'.get_script_name().'" method="post">';

	print_thread($file,1,@thread);

	print_deletion_footer($file);

	print $file '</form>';

	print_page_footer($file);
}

sub print_admin_login($)
{
	my ($file)=@_;

	print_page_header($file);
	print_admin_header($file,"");

	print $file '<div align="center">';
	print $file '<form action="'.get_script_name().'" method="get">';
	print $file 'Admin password: ';
	print $file '<input type="password" name="admin" size="8" maxlength="16" value="" /> ';
	print $file '<select name="action">';
	print $file '<option value="mpanel">'.S_MANAPANEL.'</option>';
	print $file '<option value="bans">'.S_MANABANS.'</option>';
	print $file '<option value="mpost">'.S_MANAPOST.'</option>';
	print $file '<option value="rebuild">'.S_MANAREBUILD.'</option>';
	print $file '<option value=""></option>';
	print $file '<option value="nuke">'.S_MANANUKE.'</option>';
	print $file '</select>';
	print $file '<input type="submit" value="'.S_MANASUB.'" />';
	print $file '</form></div>';

	print_page_footer($file);
}

sub print_admin_post_panel($$@)
{
	my ($file,$admin,@posts)=@_;
	my ($sth,$row,$count,$size);

	print_page_header($file);
	print_admin_header($file,$admin);

	print $file '<div class="dellist">'.S_MPTITLE.'</div>';

	print $file '<form action="'.get_script_name().'" method="post">';
	print $file '<input type="hidden" name="action" value="delete" />';
	print $file '<input type="hidden" name="admin" value="'.$admin.'" />';
	print $file '<div class="delbuttons">';
	print $file '<input type="submit" value="'.S_MPDELETE.'" />';
	print $file '<input type="reset" value="'.S_MPRESET.'" />';
	print $file '[<label><input type="checkbox" name="fileonly" value="on" />'.S_MPONLYPIC.'</label>]';
	print $file '</div>';

	print $file '<table align="center"><tbody>';
	print $file '<tr class="managehead">'.S_MPTABLE.'</tr>';

	$count=1;
	$size=0;

	foreach $row (@posts)
	{
		my ($comment)=$$row{comment}=~m!^([^<]{1,30})!;
		my ($subject)=$$row{subject}=~m!^([^<]{1,30})!;
		my ($name)=$$row{name}=~m!^([^<]{1,30})!;

		print $file '<tr class="row'.$count.'">';

		print $file '<td>' unless($$row{image});
		print $file '<td rowspan="2">' if($$row{image});
		print $file '<label>';
		print $file '<input type="checkbox" name="delete" value="'.$$row{num}.'" />';
		print $file '&nbsp;&gt;&gt;' if($$row{parent});
		print $file '&nbsp;<big><b>'.$$row{num}.'</b></big>&nbsp;&nbsp;</td>';
		print $file '<td>'.make_date($$row{timestamp},2).'</td>';
		print $file '<td>'.$subject.'</td>';
		print $file '<td><b>'.$name;
		print $file TRIPKEY.$$row{trip} if($$row{trip});
		print $file '</b></td>';
		print $file '<td>'.$comment.'</td>';
		print $file '<td>'.dec_to_dot($$row{ip});
		print ' [&nbsp;<a href="'.get_script_name().'?admin='.$admin.'&action=deleteall&ip='.$$row{ip}.'">'.S_MPDELETEALL.'</a>&nbsp;]';
		print '&nbsp;[&nbsp;<a href="'.get_script_name().'?admin='.$admin.'&action=addip&type=ipban&ip='.$$row{ip}.'">'.S_MPBAN.'</a>&nbsp;]</td>';
		print $file '</tr>';

		if($$row{image})
		{
			print $file '<tr class="row'.$count.'">';
			print $file '<td colspan="6"><small>';
			print $file S_PICNAME.'<a href="'.expand_filename($$row{image}).'">'.$$row{image}.'</a>';
			print $file ' ('.$$row{size}.' B, '.$$row{width}.'x'.$$row{height}.')';
			print $file ' &nbsp; MD5: '.$$row{md5};
			print $file '</small></td></tr>';
		}

		$size+=$$row{size} if($$row{size});
		$count^=3;
	}

	print $file '</tbody></table>';

	print $file '<div class="delbuttons">';
	print $file '<input type="submit" value="'.S_MPDELETE.'" />';
	print $file '<input type="reset" value="'.S_MPRESET.'" />';
	print $file '[<label><input type="checkbox" name="fileonly" value="on" />'.S_MPONLYPIC.'</label>]';
	print $file '</div>';

	print $file '</form>';

	print $file '<br /><div class="postarea" align="center">';

	print $file '<form action="'.get_script_name().'" method="post">';
	print $file '<input type="hidden" name="action" value="deleteall" />';
	print $file '<input type="hidden" name="admin" value="'.$admin.'" />';
	print $file '<table><tbody>';
	print $file '<tr><td class="postblock" align="left">'.S_BANIPLABEL.'</td><td align="left"><input type="text" name="ip" size="24" /></td></tr>';
	print $file '<tr><td class="postblock" align="left">'.S_BANMASKLABEL.'</td><td align="left"><input type="text" name="mask" size="24" />';
	print $file ' <input type="submit" value="'.S_MPDELETEIP.'" /></td></tr>';
	print $file '</tbody></table></form>';

	print $file '</div><br />';

	print $file sprintf S_IMGSPACEUSAGE,int($size/1024);

	print_page_footer($file);
}

sub print_admin_ban_panel($$@)
{
	my ($file,$admin,@bans)=@_;
	my ($sth,$row,$count);

	print_page_header($file);
	print_admin_header($file,$admin);

	print $file '<div class="dellist">'.S_BANTITLE.'</div>';

	print $file '<div class="postarea" align="center">';
	print $file '<table><tbody><tr><td align="bottom">';

	print $file '<form action="'.get_script_name().'" method="post">';
	print $file '<input type="hidden" name="action" value="addip" />';
	print $file '<input type="hidden" name="type" value="ipban" />';
	print $file '<input type="hidden" name="admin" value="'.$admin.'" />';
	print $file '<table><tbody>';
	print $file '<tr><td class="postblock" align="left">'.S_BANIPLABEL.'</td><td align="left"><input type="text" name="ip" size="24" /></td></tr>';
	print $file '<tr><td class="postblock" align="left">'.S_BANMASKLABEL.'</td><td align="left"><input type="text" name="mask" size="24" /></td></tr>';
	print $file '<tr><td class="postblock" align="left">'.S_BANCOMMENTLABEL.'</td><td align="left"><input type="text" name="comment" size="16" />';
	print $file ' <input type="submit" value="'.S_BANIP.'" /></td></tr>';
	print $file '</tbody></table></form>';

	print $file '</td><td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td><td valign="bottom">';

	print $file '<form action="'.get_script_name().'" method="post">';
	print $file '<input type="hidden" name="action" value="addstring" />';
	print $file '<input type="hidden" name="type" value="wordban" />';
	print $file '<input type="hidden" name="admin" value="'.$admin.'" />';
	print $file '<table><tbody>';
	print $file '<tr><td class="postblock" align="left">'.S_BANWORDLABEL.'</td><td align="left"><input type="text" name="string" size="24" /></td></tr>';
	print $file '<tr><td class="postblock" align="left">'.S_BANCOMMENTLABEL.'</td><td align="left"><input type="text" name="comment" size="16" />';
	print $file ' <input type="submit" value="'.S_BANWORD.'" /></td></tr>';
	print $file '</form>';
	print $file '</tbody></table></form>';

	print $file '</td><td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td><td valign="bottom">';

	print $file '<form action="'.get_script_name().'" method="post">';
	print $file '<input type="hidden" name="action" value="addip" />';
	print $file '<input type="hidden" name="type" value="whitelist" />';
	print $file '<input type="hidden" name="admin" value="'.$admin.'" />';
	print $file '<table><tbody>';
	print $file '<tr><td class="postblock" align="left">'.S_BANIPLABEL.'</td><td align="left"><input type="text" name="ip" size="24" /></td></tr>';
	print $file '<tr><td class="postblock" align="left">'.S_BANMASKLABEL.'</td><td align="left"><input type="text" name="mask" size="24" /></td></tr>';
	print $file '<tr><td class="postblock" align="left">'.S_BANCOMMENTLABEL.'</td><td align="left"><input type="text" name="comment" size="16" />';
	print $file ' <input type="submit" value="'.S_BANWHITELIST.'" /></td></tr>';
	print $file '</tbody></table></form>';

	print $file '</td></tr></tbody></table>';
	print $file '</div><br />';

#	print $file '<input type="reset" value="'.S_MPRESET.'" />';
#	print $file '[<label><input type="checkbox" name="fileonly" value="on" />'.S_MPONLYPIC.'</label>]';
#	print $file '</div>';

	print $file '<table align="center"><tbody>';
	print $file '<tr class="managehead">'.S_BANTABLE.'</tr>';

	$count=1;

	foreach $row (@bans)
	{
		print $file '<tr class="row'.$count.'">';
		$count^=3;

		if($$row{type} eq 'ipban')
		{
			print $file '<td>IP</td>';
			print $file '<td>'.dec_to_dot($$row{ival1}).'/'.dec_to_dot($$row{ival2}).'</td>';
		}
		elsif($$row{type} eq 'wordban')
		{
			print $file '<td>Word</td>';
			print $file '<td>'.$$row{sval1}.'</td>';
		}
		if($$row{type} eq 'whitelist')
		{
			print $file '<td>Whitelist</td>';
			print $file '<td>'.dec_to_dot($$row{ival1}).'/'.dec_to_dot($$row{ival2}).'</td>';
		}

		print $file '<td>'.$$row{comment}.'</td>';
		print $file '<td><a href="'.get_script_name().'?admin='.$admin.'&action=removeban&num='.$$row{num}.'">'.S_BANREMOVE.'</a></td>';
		print $file '</tr>';
	}

	print $file '</tbody></table><br />';

	print_page_footer($file);
}

sub print_admin_post($$)
{
	my ($file,$admin)=@_;
	my ($sth,$row,$count);

	print_page_header($file);
	print_admin_header($file,$admin);

	print $file '<div align="center"><em>'.S_NOTAGS.'</em></div>';

	print_posting_form($file,0,$admin,"");

	print_page_footer($file);
}

sub print_admin_header($$)
{
	my ($file,$admin)=@_;

	print $file '[<a href="'.expand_filename(HTML_SELF).'">'.S_MANARET.'</a>]';
	if($admin)
	{
		print $file ' [<a href="'.get_script_name().'?action=mpanel&admin='.$admin.'">'.S_MANAPANEL.'</a>]';
		print $file ' [<a href="'.get_script_name().'?action=bans&admin='.$admin.'">'.S_MANABANS.'</a>]';
		print $file ' [<a href="'.get_script_name().'?action=mpost&admin='.$admin.'">'.S_MANAPOST.'</a>]';
		print $file ' [<a href="'.get_script_name().'?action=rebuild&admin='.$admin.'">'.S_MANAREBUILD.'</a>]';
	}

	print $file '<div class="passvalid">'.S_MANAMODE.'</div><br />';
}

sub print_error($$)
{
	my ($file,$error)=@_;

	print_page_header($file);

	print $file '<div style="text-align: center; width=100%; font-size: 2em;"><br />';
	print $file $error;
	print $file '<br /><br /><a href="'.$ENV{HTTP_REFERER}.'">'.S_RETURN.'</a>';
	print $file '</div>';

	print $file '</body></html>';
}




#
# Util functions
#

sub print_page_header($)
{
	my ($file)=@_;

#	print $file '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"';
#	print $file ' "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">';
#	print $file '<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="jp">'; # lang="jp"? what the hell?
#	print $file '<head><meta http-equiv="content-type"  content="text/html;charset=utf-8" />';
#	print $file '<!-- meta HTTP-EQUIV="pragma" CONTENT="no-cache" -->';

#	print $file '<?xml version="1.0" encoding="utf-8"?>';
	print $file '<html><head>';

	print $file '<title>'.TITLE.'</title>';
	print $file '<meta http-equiv="Content-Type"  content="text/html;charset='.CHARSET.'" />' if(CHARSET);
#	print $file '<meta http-equiv="pragma" content="no-cache">';
	print $file '<link rel="stylesheet" type="text/css" href="'.expand_filename(CSS_FILE).'" title="Standard stylesheet" />';
	print $file '<link rel="shortcut icon" href="'.expand_filename(FAVICON).'" />' if(FAVICON);
	print $file '<script src="'.expand_filename(JS_FILE).'"></script>'; # could be better
	print $file '</head><body>';

	print $file S_HEAD;

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

	print $file S_FOOT;
	print $file '</body></html>';
}

sub print_posting_form($$$$)
{
	my ($file,$parent,$admin,$dummy)=@_;
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
		print $file ' <img src="'.expand_filename(CAPTCHA_SCRIPT).'?key='.$key.'&dummy='.$dummy.'" />';
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

	# display the original thread comment
	print_comment_header($file,$parent,!$threadview,1);
	print $file '<blockquote>'.$$parent{comment}.'</blockquote>';

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

	# display replies

	foreach my $res (@thread)
	{
		print $file '<table><tbody><tr><td class="doubledash">&gt;&gt;</td>';
		print $file '<td class="reply">';

		print_comment_header($file,$res,0,0);

		if($$res{image})
		{
			print $file '<br />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;';
			print_image($file,$res,!$threadview);
		}

		print $file '<blockquote>'.$$res{comment}.'</blockquote>';

		print $file '</td></tr></tbody></table>';
	}

	print $file '<br clear="left" /><hr />';
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
	print $file '-(<em>'.$$res{size}.' B, '.$$res{width}.'x'.$$res{height}.'</em>)</span>';
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
