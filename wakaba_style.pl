use strict;

BEGIN { require "wakautils.pl" }



#
# Externally called functions
#

sub print_page($$$@)
{
	my ($file,$page,$total,@threads)=@_;

	print_page_header($file);
	print $file '<div id="mainpage">';

	print_posting_form($file,0,"","");

	foreach my $thread (@threads)
	{
		print_thread($file,0,@{$thread});
	}

	print_deletion_footer($file);
	print_navi_footer($file,$page,$total);

	print $file '</div>';
	print_page_footer($file);

}

sub print_reply($@)
{
	my ($file,@thread)=@_;
	my ($sth,$row);

	print_page_header($file);
	print $file '<div id="replypage">';

	print $file '<div id="replybar">[<a href="'.expand_filename(HTML_SELF).'">'.S_RETURN.'</a>]</div>';
	print $file '<h2>'.S_POSTING.'</h2>';

	print_posting_form($file,$thread[0]{num},"",$thread[$#thread]{num});

	print_thread($file,1,@thread);

	print_deletion_footer($file);

	print $file '</div>';
	print_page_footer($file);
}

sub print_admin_login($)
{
	my ($file)=@_;

	print_page_header($file);
	print $file '<div id="login">';
	print_admin_header($file,"");

	print $file '<form action="'.get_script_name().'" method="get">';
	print $file S_ADMINPASS;
	print $file ' <input type="password" name="admin" size="8" maxlength="32" value="" />';
	print $file '&nbsp;<select name="action">';
	print $file '<option value="mpanel">'.S_MANAPANEL.'</option>';
	print $file '<option value="bans">'.S_MANABANS.'</option>';
	print $file '<option value="spam">'.S_MANASPAM.'</option>';
	print $file '<option value="mpost">'.S_MANAPOST.'</option>';
	print $file '<option value="rebuild">'.S_MANAREBUILD.'</option>';
	print $file '<option value=""></option>';
	print $file '<option value="nuke">'.S_MANANUKE.'</option>';
	print $file '</select>';
	print $file '<input type="submit" value="'.S_MANASUB.'" />';
	print $file '</form>';

	print $file '</div>';
	print_page_footer($file);
}

sub print_admin_post_panel($$@)
{
	my ($file,$admin,@posts)=@_;
	my ($sth,$row,$count,$size);

	print_page_header($file);
	print $file '<div id="posts">';
	print_admin_header($file,$admin);

	print $file '<h3>'.S_MPTITLE.'</h3>';

	print $file '<form action="'.get_script_name().'" method="post">';
	print $file '<input type="hidden" name="action" value="deleteall" />';
	print $file '<input type="hidden" name="admin" value="'.$admin.'" />';
	print $file '<table class="admininput"><tbody>';
	print $file '<tr><td class="label">'.S_BANIPLABEL.'</td><td class="input"><input type="text" name="ip" size="24" /></td></tr>';
	print $file '<tr><td class="label">'.S_BANMASKLABEL.'</td><td class="input"><input type="text" name="mask" size="24" />';
	print $file ' <input type="submit" value="'.S_MPDELETEIP.'" /></td></tr>';
	print $file '</tbody></table></form>';

	print $file '<form action="'.get_script_name().'" method="post">';
	print $file '<input type="hidden" name="action" value="delete" />';
	print $file '<input type="hidden" name="admin" value="'.$admin.'" />';

	print $file '<div class="buttons">';
	print $file '<input type="submit" value="'.S_MPDELETE.'" />';
	print $file '<input type="reset" value="'.S_MPRESET.'" />';
	print $file ' [<label><input type="checkbox" name="fileonly" value="on" />'.S_MPONLYPIC.'</label>]';
	print $file '</div>';

	print $file '<table class="admindata"><tbody>';
	print $file '<tr class="headrow">'.S_MPTABLE.'</tr>';

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
		print $file '<input type="checkbox" name="delete" value="'.$$row{num}.'" />&nbsp;';
		print $file '&gt;&gt;' if($$row{parent});
		print $file '<big>'.$$row{num}.'</big>&nbsp;&nbsp;</td>';
		print $file '<td>'.make_date($$row{timestamp},2).'</td>';
		print $file '<td>'.$subject.'</td>';
		print $file '<td><b>'.$name;
		print $file $$row{trip} if($$row{trip});
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

	print $file '<div class="buttons">';
	print $file '<input type="submit" value="'.S_MPDELETE.'" />';
	print $file '<input type="reset" value="'.S_MPRESET.'" />';
	print $file ' [<label><input type="checkbox" name="fileonly" value="on" />'.S_MPONLYPIC.'</label>]';
	print $file '</div>';

	print $file '</form>';

	print $file '<h4>'.(sprintf S_IMGSPACEUSAGE,int($size/1024)).'</h4>';

	print $file '</div>';
	print_page_footer($file);
}

sub print_admin_ban_panel($$@)
{
	my ($file,$admin,@bans)=@_;
	my ($sth,$row,$count);

	print_page_header($file);
	print $file '<div id="bans">';
	print_admin_header($file,$admin);

	print $file '<h3>'.S_BANTITLE.'</h3>';

	print $file '<div id="inputs">';

	print $file '<form action="'.get_script_name().'" method="post">';
	print $file '<input type="hidden" name="action" value="addip" />';
	print $file '<input type="hidden" name="type" value="ipban" />';
	print $file '<input type="hidden" name="admin" value="'.$admin.'" />';
	print $file '<table class="admininput"><tbody>';
	print $file '<tr><td class="label">'.S_BANIPLABEL.'</td><td class="input"><input type="text" name="ip" size="24" /></td></tr>';
	print $file '<tr><td class="label">'.S_BANMASKLABEL.'</td><td class="input"><input type="text" name="mask" size="24" /></td></tr>';
	print $file '<tr><td class="label">'.S_BANCOMMENTLABEL.'</td><td class="input"><input type="text" name="comment" size="16" />';
	print $file ' <input type="submit" value="'.S_BANIP.'" /></td></tr>';
	print $file '</tbody></table></form>';

	print $file '<form action="'.get_script_name().'" method="post">';
	print $file '<input type="hidden" name="action" value="addstring" />';
	print $file '<input type="hidden" name="type" value="wordban" />';
	print $file '<input type="hidden" name="admin" value="'.$admin.'" />';
	print $file '<table class="admininput"><tbody>';
	print $file '<tr><td class="label">'.S_BANWORDLABEL.'</td><td class="input"><input type="text" name="string" size="24" /></td></tr>';
	print $file '<tr><td class="label">'.S_BANCOMMENTLABEL.'</td><td class="input"><input type="text" name="comment" size="16" />';
	print $file ' <input type="submit" value="'.S_BANWORD.'" /></td></tr>';
	print $file '</tbody></table></form>';

	print $file '<form action="'.get_script_name().'" method="post">';
	print $file '<input type="hidden" name="action" value="addip" />';
	print $file '<input type="hidden" name="type" value="whitelist" />';
	print $file '<input type="hidden" name="admin" value="'.$admin.'" />';
	print $file '<table class="admininput"><tbody>';
	print $file '<tr><td class="label">'.S_BANIPLABEL.'</td><td class="input"><input type="text" name="ip" size="24" /></td></tr>';
	print $file '<tr><td class="label">'.S_BANMASKLABEL.'</td><td class="input"><input type="text" name="mask" size="24" /></td></tr>';
	print $file '<tr><td class="label">'.S_BANCOMMENTLABEL.'</td><td class="input"><input type="text" name="comment" size="16" />';
	print $file ' <input type="submit" value="'.S_BANWHITELIST.'" /></td></tr>';
	print $file '</tbody></table></form>';

	print $file '</div>';

	print $file '<table class="admindata"><tbody>';
	print $file '<tr class="headrow">'.S_BANTABLE.'</tr>';

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

	print $file '</tbody></table>';

	print $file '</sdiv>';
	print_page_footer($file);
}

sub print_admin_spam_panel($$@)
{
	my ($file,$admin,@spam)=@_;

	print_page_header($file);
	print $file '<div id="spam">';
	print_admin_header($file,$admin);

	print $file '<h3>'.S_SPAMTITLE.'</h3>';
	print $file '<p>'.S_SPAMEXPL.'</p>';

	print $file '<form action="'.get_script_name().'" method="post">';
	print $file '<input type="hidden" name="action" value="updatespam" />';
	print $file '<input type="hidden" name="admin" value="'.$admin.'" />';

	print $file '<div class="buttons">';
	print $file '<input type="submit" value="'.S_SPAMSUBMIT.'" />';
	print $file ' <input type="button" value="'.S_SPAMCLEAR.'" onclick="document.forms[0].spam.value=\'\'" />';
	print $file ' <input type="reset" value="'.S_SPAMRESET.'" />';
	print $file '</div>';
	print $file '<textarea name="spam" rows="'.scalar(@spam).'" cols="60">';
	print $file join "\n",map { clean_string($_) } @spam;
	print $file '</textarea>';
	print $file '<div class="buttons">';
	print $file '<input type="submit" value="'.S_SPAMSUBMIT.'" />';
	print $file ' <input type="button" value="'.S_SPAMCLEAR.'" onclick="document.forms[0].spam.value=\'\'" />';
	print $file ' <input type="reset" value="'.S_SPAMRESET.'" />';

	print $file '</div>';
	print $file '</form>';

	print $file '</div>';
	print_page_footer($file);
}

sub print_admin_post($$)
{
	my ($file,$admin)=@_;
	my ($sth,$row,$count);

	print_page_header($file);
	print $file '<div id="adminpost">';
	print_admin_header($file,$admin);

	print $file '<h3>'.S_NOTAGS.'</h3>';
	print_posting_form($file,0,$admin,"");

	print $file '</div>';
	print_page_footer($file);
}

sub print_admin_header($$)
{
	my ($file,$admin)=@_;

	print $file '<div id="managerbar">';
	print $file '[<a href="'.expand_filename(HTML_SELF).'">'.S_MANARET.'</a>]';
	if($admin)
	{
		print $file ' [<a href="'.get_script_name().'?action=mpanel&admin='.$admin.'">'.S_MANAPANEL.'</a>]';
		print $file ' [<a href="'.get_script_name().'?action=bans&admin='.$admin.'">'.S_MANABANS.'</a>]';
		print $file ' [<a href="'.get_script_name().'?action=spam&admin='.$admin.'">'.S_MANASPAM.'</a>]';
		print $file ' [<a href="'.get_script_name().'?action=mpost&admin='.$admin.'">'.S_MANAPOST.'</a>]';
		print $file ' [<a href="'.get_script_name().'?action=rebuild&admin='.$admin.'">'.S_MANAREBUILD.'</a>]';
	}
	print $file '</div>';

	print $file '<h2>'.S_MANAMODE.'</h2>';
}

sub print_error($$)
{
	my ($file,$error)=@_;

	print_page_header($file);

	print $file '<div id="error">';
	print $file '<h2>'.$error.'</h2>';
	print $file '<h3><a href="'.$ENV{HTTP_REFERER}.'">'.S_RETURN.'</a></h3>';
	print $file '</div>';

	print $file '</body></html>';
}



#
# Util functions
#

sub print_page_header($)
{
	my ($file)=@_;
	my @styles=get_stylesheets();

	print $file '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"';
	print $file ' "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">';
	print $file '<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en"><head>';

	print $file '<title>'.TITLE.'</title>';
	print $file '<meta http-equiv="Content-Type"  content="text/html;charset='.CHARSET.'" />' if(CHARSET);

	foreach my $style (@styles)
	{
		print $file '<link rel="';
		print $file 'alternate ' unless($$style{title} eq DEFAULT_STYLE);
		print $file 'stylesheet" type="text/css" href="'.expand_filename($$style{filename}).'" title="'.$$style{title}.'" />';
	}

	print $file '<link rel="shortcut icon" href="'.expand_filename(FAVICON).'" />' if(FAVICON);
	print $file '<script type="text/javascript" src="'.expand_filename(JS_FILE).'"></script>';
	print $file '</head><body>';

	print $file S_HEAD;

	print $file '<div id="adminbar">';
	print $file '[<a href="'.expand_filename(HOME).'" target="_top">'.S_HOME.'</a>]';
	print $file ' [<a href="'.get_secure_script_name().'?action=admin">'.S_ADMIN.'</a>]';
	print $file '</div>';

	print $file '<div id="stylebar">';
	foreach my $style (@styles)
	{
		print $file '[<a href="javascript:set_stylesheet(\''.$$style{title}.'\')">'.$$style{title}.'</a>] ';
	}
	print $file '</div>';

	print $file '<div id="title">';
	print $file '<img src="'.expand_filename(TITLEIMG).'" alt="'.TITLE.'" />' if(SHOWTITLEIMG==1);
	print $file '<img src="'.expand_filename(TITLEIMG).'" onclick="this.src=this.src;" alt="'.TITLE.'" />' if(SHOWTITLEIMG==2);
	print $file '<h1>'.TITLE.'</h1>' if(SHOWTITLETXT);
	print $file '<hr /></div>';
}

sub print_page_footer($)
{
	my ($file)=@_;

	print $file '<div id="footer">'.S_FOOT.'</div>';
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

	print $file '<div id="postarea">';
	print $file '<form name="postform" action="'.get_script_name().'" method="post" enctype="multipart/form-data">';
	print $file '<input type="hidden" name="action" value="post" />';
	print $file '<input type="hidden" name="parent" value="'.$parent.'" />' if($parent);
	print $file '<input type="hidden" name="admin" value="'.$admin.'" />' if($admin);
	print $file '<table><tbody>';
	print $file '<tr><td class="label">'.S_NAME.'</td><td class="input"><input type="text" name="name" size="28" /></td></tr>';
	print $file '<tr><td class="label">'.S_EMAIL.'</td><td class="input"><input type="text" name="email" size="28" /></td></tr>';
	print $file '<tr><td class="label">'.S_SUBJECT.'</td><td class="input"><input type="text" name="subject" size="35" />';
	print $file ' <input type="submit" value="'.S_SUBMIT.'" /></td></tr>';
	print $file '<tr><td class="label">'.S_COMMENT.'</td><td class="input"><textarea name="comment" cols="48" rows="4"></textarea></td></tr>';

	if($image_inp)
	{
		print $file '<tr><td class="label">'.S_UPLOADFILE.'</td><td class="input"><input type="file" name="file" size="35" />';
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

		print $file '<tr><td class="label">'.S_CAPTCHA.'</td><td class="input"><input type="text" name="captcha" size="10" />';
		print $file ' <img class="captcha" src="'.expand_filename(CAPTCHA_SCRIPT).'?key='.$key.'&dummy='.$dummy.'" />';
		print $file '</td></tr>';
	}

#	print $file '<tr><td class="postblock" align="left">'.S_DELPASS.'</td><td align="left"><input type="password" name="password" size="8" maxlength="8" value="'.$c_password.'" /> '.S_DELEXPL2.'</td></tr>';
	print $file '<tr><td class="label">'.S_DELPASS.'</td><td class="input"><input type="password" name="password" size="8" maxlength="8" /> '.S_DELEXPL.'</td></tr>';

	print $file '<tr><td colspan="2"><div id="rules">'.S_RULES.'</div></td></tr>';

	print $file '</tbody></table></form></div>';
	print $file '<script type="text/javascript">with(document.postform) {if(!name.value) name.value=get_cookie("name"); if(!email.value) email.value=get_cookie("email"); if(!password.value) password.value=get_password("password"); }</script>';

	print $file '<hr />';

	print $file '<form name="delform" action="'.get_script_name().'" method="post">';
}

sub print_thread($$@)
{
	my ($file,$threadview,@thread)=@_;
	my ($parent,$replies);

 	# remove parent post from start of thread 
 	$parent=shift @thread;

	print $file '<div class="threadcontainer"><div class="thread"><div class="threadstart">';

	# display image
	print_comment_header($file,$parent,!$threadview,1);
	print_image($file,$parent,0) if($$parent{image});

	# display the original thread comment
	print_comment($file,$parent,$threadview);

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

		if($images) { print $file '<span class="omittedposts">'.(sprintf S_ABBRIMG,$omit,$images).'</span>' }
		else { print $file '<span class="omittedposts">'.(sprintf S_ABBR,$omit).'</span>'; }
	}
	print $file '</div>';

	# display replies

	if(@thread)
	{
		print $file '<div class="replies">';
		foreach my $res (@thread)
		{
			print $file '<div class="replycontainer">';
			print $file '<div class="reply" id="reply'.$$res{num}.'">';

			print_comment_header($file,$res,0,0);
			print_image($file,$res,!$threadview) if($$res{image});
			print_comment($file,$res,!$threadview);

			print $file '</div></div>';
		}
		print $file '</div>';
	}

	print $file '<hr /></div></div>';
}

sub print_comment_header($$$$)
{
	my ($file,$res,$frontpage,$toplevel)=@_;
	my ($titleclass,$nameclass);

	$titleclass=$toplevel?"filetitle":"replytitle";
	$nameclass=$toplevel?"postername":"commentpostername";

	print $file '<a name="'.$$res{num}.'"></a>';

	print $file $toplevel?'<h3>':'<h4>';
	print $file '<label><input type="checkbox" name="delete" value="'.$$res{num}.'" />';
	print $file '<strong>'.$$res{subject}.'</strong>';
	print $file ' <em>';
	print $file '<a href="mailto:'.$$res{email}.'">' if($$res{email});
	print $file $$res{name};
	print $file '</a>' if($$res{email});

	if($$res{trip})
	{
		print $file '<small>';
		print $file '<a href="mailto:'.$$res{email}.'">' if($$res{email});
		print $file TRIPKEY if($$res{trip} and eval { my $t=quotemeta TRIPKEY; $$res{trip}!~/^$t/ or $$res=~/^$t.{8}/ }); # ugly kludge to deal with old-style trips
		print $file $$res{trip};
		print $file '</a>' if($$res{email});
		print $file '</small>';
	}

	print $file '</em>';
	print $file ' '.$$res{date}.'</label>';
	print $file ' <span class="reflink"><a href="javascript:insert(\'>>'.$$res{num}.'\')">No.'.$$res{num}.'</a></span>';
	print $file ' <span class="replylink">[<a href="'.get_reply_link($$res{num},0).'">'.S_REPLY.'</a>]</span>' if($frontpage);

	print $file $toplevel?'</h3>':'</h4>';
}

sub print_comment($$$)
{
	my ($file,$res,$abbreviate)=@_;
	my $abbreviation;

	if($abbreviate and $abbreviation=abbreviate_html($$res{comment},MAX_LINES_SHOWN,APPROX_LINE_LENGTH))
	{
		print $file '<div class="replytext">',$abbreviation.'</div>';
		print $file '<div class="replyabbrev">'.sprintf(S_ABBRTEXT,get_reply_link($$res{num},$$res{parent})).'</div>';
	}
	else
	{
		print $file '<div class="replytext">'.$$res{comment}.'</div>';
	}
}

sub print_image($$$)
{
	my ($file,$res,$hidden)=@_;
 	$$res{image}=~m!([^/]+)$!;
 	my ($imagename)=$1;

	$hidden=0 unless(HIDE_IMAGE_REPLIES);

	print $file '<h5>'.S_PICNAME.'<a target="_blank" href="'.expand_filename($$res{image}).'">'.$imagename.'</a>';
	print $file '-(<em>'.$$res{size}.' B, '.$$res{width}.'x'.$$res{height}.'</em>)';
	print $file ' <small>'.S_THUMB.'</small>' unless($hidden);
	print $file ' <small>'.S_HIDDEN.'</small>' if($hidden);
	print $file '</h5>';

	unless($hidden)
	{
		if($$res{thumbnail})
		{
			print $file '<div class="thumbnail">';
			print $file '<a target="_blank" href="'.expand_filename($$res{image}).'">';
			print $file '<img src="'.expand_filename($$res{thumbnail}).'"';
			print $file ' width="'.$$res{tn_width}.'" height="'.$$res{tn_height}.'" alt="'.$$res{size}.'" />';
			print $file '</a>';
			print $file '</div>';
		}
		else
		{
			print $file '<div class="nothumbnail">';
			print $file '<a target="_blank" href="'.expand_filename($$res{image}).'">'.S_NOTHUMB.'</a>';
			print $file '</div>';
		}
	}
}

sub print_deletion_footer($)
{
	my ($file)=@_;

	print $file '<div id="delete">';
	print $file '<input type="hidden" name="action" value="delete" />';
	print $file S_REPDEL.'[<label><input type="checkbox" name="fileonly" value="on" />'.S_DELPICONLY.'</label>]<br />';
#	print $file S_DELKEY.'<input type="password" name="password" value="'.$c_password.'" maxlength="8" size="8" />';
	print $file S_DELKEY.'<input type="password" name="password" maxlength="8" size="8" />';
	print $file '<input value="'.S_DELETE.'" type="submit" />';
	print $file '</div></form>';
	print $file '<script type="text/javascript">document.delform.password.value=get_cookie("password");</script>';
}

sub print_navi_footer($$$)
{
	my ($file,$page,$total)=@_;
	my (@pages,$i);

	@pages=get_page_links($total);

	print $file '<div id="navibar"><div id="naviprev">';

	if($page==0) { print $file S_FIRSTPG }
	else { print $file '<a href="'.$pages[$page-1].'">'.S_PREV.'</a>' }

	print $file '</div><div id="navilinks">';

	for($i=0;$i<$total;$i++)
	{
		if($i==$page)
		{ print $file '['.$i.'] ' }
		else
		{ print $file '[<a href="'.$pages[$i].'">'.$i.'</a>] '; }
	}

	print $file '</div><div id="navinext">';

	if($page==$total-1) { print $file S_LASTPG }
	else { print $file '<a href="'.$pages[$page+1].'">'.S_NEXT.'</a>' }

	print $file '</div></div>';
}

1;
