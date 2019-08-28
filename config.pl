# use encoding 'shift-jis'; # Uncomment this to use shift-jis in strings. ALSO uncomment the "no encoding" at the end of the file!

# System config
use constant ADMIN_PASS => 'CHANGEME';		# Admin password. For fucks's sake, change this.
use constant SQL_DBI_SOURCE => 'DBI:mysql:database=CHANGEME;host=localhost';			# DBI data source string (put server and database name in here)
use constant SQL_USERNAME => 'CHANGEME';							# MySQL login name
use constant SQL_PASSWORD => 'CHANGEME';						# MySQL password
#use constant SQL_DBI_SOURCE => 'dbi:SQLite:dbname=wakaba.sql';		# DBI data source string (put SQLite filename in here)
#use constant SQL_USERNAME => '';					# Not used by SQLite
#use constant SQL_PASSWORD => '';					# Not used by SQLite
use constant SQL_TABLE => 'comments';					# Table (NOT DATABASE) used by image board
use constant SQL_ADMIN_TABLE => 'admin';
use constant USE_TEMPFILES => 1;				# Set this to 1 under Unix and 0 under Windows! (Use tempfiles when creating pages)

# Page look
use constant TITLE => 'Wakaba image board';	# Name of this image board
use constant SHOWTITLETXT => 1;			# Show TITLE at top (1: yes  0: no)
use constant SHOWTITLEIMG => 0;			# Show image at top (0: no, 1: single, 2: rotating)
use constant TITLEIMG => 'title.jpg';		# Title image (point to php file if rotating)
use constant FAVICON => '';			# Favicon.ico file
use constant HOME => '../';			# Site home directory (up one level by default
use constant IMAGES_PER_PAGE => 10;		# Images per page
use constant REPLIES_PER_THREAD => 10;           # Replies shown
use constant S_ANONAME => 'Anonymous';			# Defines what to print if there is no text entered in the name field
use constant S_ANOTEXT => '';				# Defines what to print if there is no text entered in the comment field
use constant S_ANOTITLE => '';			# Defines what to print if there is no text entered into subject field

# Limitations
use constant MAX_KB => 500;			# Maximum upload size in KB
use constant MAX_W => 200;			# Images exceeding this width will be thumbnailed
use constant MAX_H => 200;			# Images exceeding this height will be thumbnailed
use constant MAX_RES => 20;			# Maximum topic bumps
use constant MAX_POSTS => 500;			# Maximum number of posts (set to 0 to disable)
use constant MAX_THREADS => 0;			# Maximum number of threads (set to 0 to disable)
use constant MAX_AGE => 0;			# Maximum age of a thread in hours (set to 0 to disable)
use constant MAX_FIELD_LENGTH => 100;	# Maximum number of characters in subject, name, and email
use constant MAX_COMMENT_LENGTH => 1000;	# Maximum number of characters in a comment
use constant MAX_LINES => 15;			# Max lines per post (0 = no limit)

# Captcha
use constant ENABLE_CAPTCHA => 1;
use constant SQL_CAPTCHA_TABLE => 'captcha';	# Use a different captcha table for each board, if you have more than one!
use constant CAPTCHA_LIFETIME => 1440;	# Captcha lifetime in seconds
use constant CAPTCHA_CLARITY => 15;
use constant CAPTCHA_SPACING => 2;
use constant CAPTCHA_SCRIPT => 'captcha.pl';

# Tweaks
use constant THUMBNAIL_SMALL => 1;		# Thumbnail small images (1: yes, 0: no)
use constant THUMBNAIL_QUALITY => 70;	# Thumbnail JPEG quality
use constant ALLOW_TEXTONLY => 1;		# Allow textonly posts (1: yes, 0: no)
use constant ALLOW_IMAGES => 1;			# Allow image posting (1: yes, 0: no)
use constant ALLOW_TEXT_REPLIES => 1;	# Allow replies (1: yes, 0: no)
use constant ALLOW_IMAGE_REPLIES => 1;	# Allow replies with images (1: yes, 0: no)
use constant ALLOW_UNKNOWN => 1;		# Allow unknown filetypes (1: yes, 0: no)
use constant RENZOKU => 5;				# Seconds between posts (floodcheck)
use constant RENZOKU2 => 10;			# Seconds between image posts (floodcheck)
use constant RENZOKU3 => 900;			# Seconds between identical posts (floodcheck)
use constant PROXY_CHECK => ();		# Ports to scan for proxies.
#use constant PROXY_CHECK => (80,8080);	# Ports to scan for proxies.
use constant CHARSET => 'utf-8';		# Character set to use, typically 'utf-8' or 'shift_jis'. Disable charset handling by setting to ''. Remember to set Apache to use the same character set for .html files! (AddCharset shift_jis html)
use constant TRIM_METHOD => 0;			# Which threads to trim (0: oldest - like futaba 1: least active - furthest back)
use constant DATE_STYLE => 0;			# Date style (0: futaba 1: localtime 2: compact)
use constant DISPLAY_ID => 0;			# Display user IDs (0: never, 1: if no email, 2:always)
use constant EMAIL_ID => 'Heaven';		# ID string to use when DISPLAY_ID is 1 and the user uses an email.
use constant TRIPKEY => '!';			# this character is displayed before tripcodes

# Internal paths and files - might as well leave this alone.
use constant IMG_DIR => 'src/';			# Image directory (needs to be writeable by the script)
use constant THUMB_DIR => 'thumb/';		# Thumbnail directory (needs to be writeable by the script)
use constant RES_DIR => 'res/';			# Reply cache directory (needs to be writeable by the script)
use constant HTML_SELF => 'wakaba.html';	# Name of main html file
use constant CSS_FILE => 'wakaba.css';		# location of the css file
use constant JS_FILE => 'wakaba.js';		# location of the js file
use constant PAGE_EXT => '.html';		# Extension used for board pages after first
use constant ERRORLOG => '';			# Writes out all errors seen by user, mainly useful for debugging
use constant CONVERT_COMMAND => 'convert';	# location of the ImageMagick convert command (usually just 'convert', but sometime a full path is needed)
#use constant CONVERT_COMMAND => '/usr/X11R6/bin/convert';

# no encoding; # Uncomment this if you uncommented the "use encoding" at the top of the file

1;
