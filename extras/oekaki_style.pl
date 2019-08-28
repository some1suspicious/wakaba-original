use strict;

BEGIN { require 'oekaki_config.pl'; }
BEGIN { require 'oekaki_strings_e.pl'; }
BEGIN { require 'futaba_style.pl'; }



sub print_posting_form($$$$@)
{
	my ($file,$parent,$admin,$dummy,@thread)=@_;
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

	if($image_inp)
	{
		print $file '<hr />' if($parent);
		print $file '<div align="center">';
		print $file '<form action="'.expand_filename('paint.pl').'" method="get">';
		print $file '<input type="hidden" name="oek_parent" value="'.$parent.'" />' if($parent);

		print $file S_OEKPAINT.'<select class=button name="oek_painter">';
		my %names=S_OEKNAMES;
		foreach my $painter (sort keys %names)
		{
			print $file '<option value="'.$painter.'"';
			print $file ' selected="selected"' if($painter eq OEKAKI_DEFAULT_PAINTER);
			print $file '>'.$names{$painter}.'</option>';
		}
		print $file '</select>&nbsp;';

		print $file S_OEKX.'<input type="text" name="oek_x" size="3" value="'.OEKAKI_DEFAULT_X.'" />&nbsp;';
		print $file S_OEKY.'<input type="text" name="oek_y" size="3" value="'.OEKAKI_DEFAULT_Y.'" />&nbsp;';

		if(OEKAKI_ENABLE_MODIFY and $parent)
		{
			print $file S_OEKSOURCE.'<select class=button name="oek_src"><option value="">'.S_OEKNEW.'</option>';
			foreach my $res (@thread)
			{
				if($$res{image})
				{
					print $file '<option value="'.$$res{image}.'">';
					print $file sprintf S_OEKMODIFY,$$res{num};
					print $file '</option>';
				}
			}
			print $file '</select>&nbsp;';
		}

		print $file '<input type="submit" value="'.S_OEKSUBMIT.'" />';
		print $file '</form>';
		print $file '</div><hr />';
	}

	print $file '<div class="postarea" align="center">';
	print $file '<form name="postform" action="'.get_script_name().'" method="post" enctype="multipart/form-data">';
	print $file '<input type="hidden" name="action" value="post" />';
	print $file '<input type="hidden" name="parent" value="'.$parent.'" />' if($parent);
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

	if(ENABLE_CAPTCHA and !$admin)
	{
		my $key=get_captcha_key($parent);

		print $file '<tr><td class="postblock" align="left">'.S_CAPTCHA.'</td><td><input type="text" name="captcha" size="10" />';
		print $file ' <img src="'.expand_filename(CAPTCHA_SCRIPT).'?key='.$key.'&dummy='.$dummy.'" />';
		print $file '</td></tr>';
	}

	if($admin)
	{
		print $file '<input type="hidden" name="admin" value="'.$admin.'" />';
		print $file '<input type="hidden" name="no_captcha" value="1" />';
		print $file '<input type="hidden" name="no_format" value="1" />';
		print $file '<tr><td class="postblock" align="left">'.S_PARENT.'</td><td align="left"><input type="text" name="parent" size="8" /></td></tr>';
	}

#	print $file '<tr><td class="postblock" align="left">'.S_DELPASS.'</td><td align="left"><input type="password" name="password" size="8" maxlength="8" value="'.$c_password.'" /> '.S_DELEXPL2.'</td></tr>';
	print $file '<tr><td class="postblock" align="left">'.S_DELPASS.'</td><td align="left"><input type="password" name="password" size="8" maxlength="8" /> '.S_DELEXPL.'</td></tr>';
	print $file '<tr><td colspan="2">';
	print $file '<div align="left" class="rules">'.S_RULES.'</div></td></tr>';
	print $file '</tbody></table></form></div><hr />';
	print $file '<script type="text/javascript">with(document.postform) {if(!name.value) name.value=get_cookie("name"); if(!email.value) email.value=get_cookie("email"); if(!password.value) password.value=get_password("password"); }</script>';
}

1;

