use constant S_HOME => 'Home';										# Forwards to home page
use constant S_ADMIN => 'Manage';									# Forwards to Management Panel
use constant S_RETURN => 'Return';									# Returns to image board
use constant S_POSTING => 'Posting mode: Reply';							# Prints message in red bar atop the reply screen

use constant S_NAME => 'Name';										# Describes name field
use constant S_EMAIL => 'E-mail';									# Describes e-mail field
use constant S_SUBJECT => 'Subject';									# Describes subject field
use constant S_SUBMIT => 'Submit';									# Describes submit button
use constant S_COMMENT => 'Comment';									# Describes comment field
use constant S_UPLOADFILE => 'File';									# Describes file field
use constant S_NOFILE => 'No File';									# Describes file/no file checkbox
use constant S_CAPTCHA => 'Verification';									# Describes captcha field
use constant S_DELPASS => 'Password';									# Describes password field
use constant S_DELEXPL => '(Password used for file deletion)';						# Prints explanation for password box (to the right)
use constant S_RULES => '<ul><li>Supported file types are: GIF, JPG, PNG</li>'.
             '<li>Maximum file size allowed is '.MAX_KB.' KB.</li>'.
             '<li>Images greater than '.MAX_W.'x'.MAX_H.' pixels will be thumbnailed.</li></ul>';	# Prints rules under posting section

use constant S_THUMB => 'Thumbnail displayed, click image for full size.';				# Prints instructions for viewing real source
use constant S_HIDDEN => 'Image reply hidden, click name for full image.';				# Prints instructions for viewing hidden image reply
use constant S_NOTHUMB => 'No<br />thumbnail';							# Printed when there's no thumbnail
use constant S_PICNAME => 'File: ';									# Prints text before upload name/link
use constant S_REPLY => 'Reply';									# Prints text for reply link
use constant S_OLD => 'Marked for deletion (old).';							# Prints text to be displayed before post is marked for deletion, see: retention
use constant S_ABBR => '%d posts omitted. Click Reply to view.';						# Prints text to be shown when replies are hidden
use constant S_ABBRIMG => '%d posts and %d images omitted. Click Reply to view.';						# Prints text to be shown when replies and images are hidden

use constant S_REPDEL => 'Delete Post ';								# Prints text next to S_DELPICONLY (left)
use constant S_DELPICONLY => 'File Only';								# Prints text next to checkbox for file deletion (right)
use constant S_DELKEY => 'Password ';									# Prints text next to password field for deletion (left)
use constant S_DELETE => 'Delete';									# Defines deletion button's name

use constant S_PREV => 'Previous';									# Defines previous button
use constant S_FIRSTPG => 'Previous';									# Defines previous button
use constant S_NEXT => 'Next';										# Defines next button
use constant S_LASTPG => 'Next';									# Defines next button

use constant S_HEAD => '';

use constant S_FOOT => '<div class="footer">'.
                       '- <a href="http://wakaba.c3.cx/">wakaba</a>'.
                       ' + <a href="http://www.2chan.net/">futaba</a>'.
                       ' + <a href="http://www.1chan.net/futallaby/">futallaby</a>'.
                       ' -</div>';					# Prints footer

use constant S_RELOAD => 'Return';									# Reloads the image board (refresh)
use constant S_MANAGEMENT => 'Manager : ';								# Defines prefix for Manager Post name
use constant S_DELETION => 'Deletion';									# Prints deletion message with quotes?
use constant S_WEEKDAYS => ('Sun','Mon','Tue','Wed','Thu','Fri','Sat');				# Defines abbreviated weekday names.
#define(S_SCRCHANGE, 'Updating page.');									//Defines message to be displayed when post is successful									//

use constant S_MANARET => 'Return';									# Returns to HTML file instead of PHP--thus no log/SQLDB update occurs
use constant S_MANAUPD => 'Update';									# Updates the log/SQLDB by accessing the PHP file
use constant S_MANAMODE => 'Manager Mode';								# Prints heading on top of Manager page
use constant S_MANAPANEL => 'Management Panel';								# Defines Management Panel radio button--allows the user to view the management panel (overview of all posts)
use constant S_MANABANS => 'Bans';									# Defines Management Panel radio button--allows the user to view the management panel (overview of all posts)
use constant S_MANAPOST => 'Manager Post';								# Defines Manager Post radio button--allows the user to post using HTML code in the comment box
use constant S_MANAREBUILD => 'Rebuild caches';							# 
use constant S_MANANUKE => 'Nuke board';								# 
use constant S_MANASUB => 'Go';										# Defines name for submit button in Manager Mode

use constant S_NOTAGS => 'HTML tags are allowed.';							# Prints message on Management Board

use constant S_MPTITLE => 'Management Panel';							# Prints sub-heading of Management Panel
use constant S_MPDELETEIP => 'Delete all';
use constant S_MPDELETE => 'Delete';									# Defines for deletion button in Management Panel
use constant S_MPRESET => 'Reset';									# Defines name for field reset button in Management Panel
use constant S_MPONLYPIC => 'File Only';								# Sets whether or not to delete only file, or entire post/thread
use constant S_MPDELETEALL => 'Del&nbsp;all';								# 
use constant S_MPBAN => 'Ban';								# Sets whether or not to delete only file, or entire post/thread
use constant S_MPTABLE => '<th>Post No.</th><th>Time</th><th>Subject</th>'.
                          '<th>Name</th><th>Comment</th><th>IP</th>';		# Explains names for Management Panel
use constant S_IMGSPACEUSAGE => '[ Space used: %d KB ]';								# Prints space used KB by the board under Management Panel

use constant S_BANTITLE => 'Ban Panel';
use constant S_BANTABLE => '<th>Type</th><th>Value</th><th>Comment</th><th>Action</th>'; # Explains names for Ban Panel
use constant S_BANIPLABEL => 'IP';
use constant S_BANMASKLABEL => 'Mask';
use constant S_BANCOMMENTLABEL => 'Comment';
use constant S_BANWORDLABEL => 'Word';
use constant S_BANIP => 'Ban IP';
use constant S_BANWORD => 'Ban word';
use constant S_BANWHITELIST => 'Whitelist';
use constant S_BANREMOVE => 'Remove';
use constant S_BANCOMMENT => 'Comment';
#define(S_RESET, 'Reset');										//Sets name for field reset button (global)

use constant S_TOOBIG => 'This image is too large!  Upload something smaller!';
use constant S_TOOBIGORNONE => 'Either this image is too big or there is no image at all.  Yeah.';
use constant S_REPORTERR => 'Error: Cannot find reply.';						# Returns error when a reply (res) cannot be found
use constant S_UPFAIL => 'Error: Upload failed.';							# Returns error for failed upload (reason: unknown?)
use constant S_NOREC => 'Error: Cannot find record.';							# Returns error when record cannot be found
#use constant S_SAMEPIC => 'Error: Duplicate md5 checksum detected.';					# Returns error when an md5 checksum is banned
use constant S_NOCAPTCHA => 'Error: No verification code on record - it probably timed out.';					# Returns error when there's no captcha in the database for this IP/key
use constant S_BADCAPTCHA => 'Error: Wrong verification code entered.';					# Returns error when the captcha is wrong
use constant S_BADFORMAT => 'Error: File format not supported.';					# Returns error when the file is not in a supported format.
use constant S_STRREF => 'Error: String refused.';								#Returns error when a string is refused
use constant S_UNJUST => 'Error: Unjust POST.';								# Returns error on an unjust POST - prevents floodbots or ways not using POST method?
use constant S_NOPIC => 'Error: No file selected.';							# Returns error for no file selected and override unchecked
use constant S_NOTEXT => 'Error: No text entered.';							# Returns error for no text entered in to subject/comment
use constant S_TOOLONG => 'Error: Field too long.';							# Returns error for too many characters in a given field
use constant S_NOTALLOWED => 'Error: Posting not allowed.';							# Returns error for non-allowed post types
use constant S_UNUSUAL => 'Error: Abnormal reply.';							# Returns error for abnormal reply? (this is a mystery!)
use constant S_BADHOST => 'Error: Host is banned.';							# Returns error for banned host ($badip string)
use constant S_RENZOKU => 'Error: Flood detected, post discarded.';					# Returns error for $sec/post spam filter
use constant S_RENZOKU2 => 'Error: Flood detected, file discarded.';					# Returns error for $sec/upload spam filter
use constant S_RENZOKU3 => 'Error: Flood detected.';							# Returns error for $sec/similar posts spam filter.
use constant S_PROXY => 'Error: Proxy detected on port %d.';						# Returns error for proxy detection.
use constant S_DUPE => 'Error: Duplicate file entry detected.';						# Returns error when an md5 checksum already exists.
use constant S_NOTHREADERR => 'Error: Thread specified does not exist.';				# Returns error when a non-existant thread is accessed
use constant S_BADDELPASS => 'Error: Password incorrect.';						# Returns error for wrong password (when user tries to delete file)
use constant S_WRONGPASS => 'Error: Management password incorrect.';					# Returns error for wrong password (when trying to access Manager modes)
use constant S_VIRUS => 'Error: Possible virus-infected file.';						# Returns error for malformed files suspected of being virus-infected.
#define(S_CANNOTWRITE, 'Error: Cannot write to directory.<br>');						//Returns error when the script cannot write to the directory, this is used on initial setup--check your chmod (777)
use constant S_NOTWRITE => 'Error: Cannot write to directory.';						# Returns error when the script cannot write to the directory, the chmod (777) is wrong
#define(S_NOTREAD, 'Error: Cannot read from directory.<br>');						//Returns error when the script cannot read from the directory, the chmod (777) is wrong
#define(S_NOTDIR, 'Error: Directory does not exist.<br>');						//Returns error when the script cannot find/read from the directory (does not exist/isn't directory), the chmod (777) is wrong

use constant S_SQLCONF => 'SQL connection failure';							# Database connection failure
use constant S_SQLFAIL => 'Critical SQL problem!';							# SQL Failure
#define(S_SQLDBSF, 'Database error, check SQL settings<br>');	//database select failure
#define(S_TCREATE, 'Creating table!<br>\n');	//creating table
#define(S_TCREATEF, 'Unable to create table!<br>');		//table creation failed

#use constant S_UPGOOD => ' '.$upfile_name.' uploaded!<br><br>';					#Defines message to be displayed when file is successfully uploaded

1;

