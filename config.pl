# use encoding 'shift-jis'; # Uncomment this to use shift-jis in strings. ALSO uncomment the "no encoding" at the end of the file!

#
# Example config file.
# 
# Uncomment and edit the options you want to specifically change from the
# default values. You must specify ADMIN_PASS, NUKE_PASS, SECRET and the
# SQL_ options.
#

# System config
#use constant ADMIN_PASS => 'CHANGEME';			# Admin password. For fucks's sake, change this.
#use constant NUKE_PASS => 'CHANGEME';			# Password to nuke a board. Change this too, NOW!
#use constant SECRET => 'CHANGEME';				# Cryptographic secret. CHANGE THIS to something totally random, and long.
#use constant SQL_DBI_SOURCE => 'DBI:mysql:database=CHANGEME;host=localhost'; # DBI data source string (mysql version, put server and database name in here)
#use constant SQL_USERNAME => 'CHANGEME';		# MySQL login name
#use constant SQL_PASSWORD => 'CHANGEME';		# MySQL password
##use constant SQL_DBI_SOURCE => 'dbi:SQLite:dbname=wakaba.sql';		# DBI data source string (SQLite version, put database filename in here)
##use constant SQL_USERNAME => '';				# Not used by SQLite
##use constant SQL_PASSWORD => '';				# Not used by SQLite
#use constant SQL_TABLE => 'comments';			# Table (NOT DATABASE) used by image board
#use constant SQL_ADMIN_TABLE => 'admin';		# Table used for admin information
#use constant USE_TEMPFILES => 1;				# Set this to 1 under Unix and 0 under Windows! (Use tempfiles when creating pages)

# Page look
#use constant TITLE => 'Wakaba image board';	# Name of this image board
#use constant SHOWTITLETXT => 1;				# Show TITLE at top (1: yes  0: no)
#use constant SHOWTITLEIMG => 0;				# Show image at top (0: no, 1: single, 2: rotating)
#use constant TITLEIMG => 'title.jpg';			# Title image (point to php file if rotating)
#use constant FAVICON => 'wakaba.ico';			# Favicon.ico file
#use constant HOME => '../';					# Site home directory (up one level by default
#use constant IMAGES_PER_PAGE => 10;			# Images per page
#use constant REPLIES_PER_THREAD => 10;			# Replies shown
#use constant IMAGE_REPLIES_PER_THREAD => 0;	# Number of image replies per thread to show, set to 0 for no limit.
#use constant S_ANONAME => 'Anonymous';			# Defines what to print if there is no text entered in the name field
#use constant S_ANOTEXT => '';					# Defines what to print if there is no text entered in the comment field
#use constant S_ANOTITLE => '';					# Defines what to print if there is no text entered into subject field
#use constant DEFAULT_STYLE => 'Futaba';		# Title of the default style for the board.

# Limitations
#use constant MAX_KB => 1000;					# Maximum upload size in KB
#use constant MAX_W => 200;						# Images exceeding this width will be thumbnailed
#use constant MAX_H => 200;						# Images exceeding this height will be thumbnailed
#use constant MAX_RES => 20;					# Maximum topic bumps
#use constant MAX_POSTS => 500;					# Maximum number of posts (set to 0 to disable)
#use constant MAX_THREADS => 0;					# Maximum number of threads (set to 0 to disable)
#use constant MAX_AGE => 0;						# Maximum age of a thread in hours (set to 0 to disable)
#use constant MAX_FIELD_LENGTH => 100;			# Maximum number of characters in subject, name, and email
#use constant MAX_COMMENT_LENGTH => 8192;		# Maximum number of characters in a comment
#use constant MAX_LINES_SHOWN => 15;			# Max lines shown per post (0 = no limit)
#use constant MAX_IMAGE_WIDTH => 16384;			# Maximum width of image before rejecting
#use constant MAX_IMAGE_HEIGHT => 16384;		# Maximum height of image before rejecting
#use constant MAX_IMAGE_PIXELS => 50000000;		# Maximum width*height of image before rejecting

# Captcha
#use constant ENABLE_CAPTCHA => 1;
#use constant SQL_CAPTCHA_TABLE => 'captcha';	# Use a different captcha table for each board, if you have more than one!
#use constant CAPTCHA_LIFETIME => 1440;			# Captcha lifetime in seconds
#use constant CAPTCHA_SCRIPT => 'captcha.pl';
#use constant CAPTCHA_HEIGHT => 18;
#use constant CAPTCHA_SCRIBBLE => 0.2;
#use constant CAPTCHA_SCALING => 0.15;
#use constant CAPTCHA_ROTATION => 0.3;
#use constant CAPTCHA_SPACING => 2.5;

# Tweaks
#use constant THUMBNAIL_SMALL => 1;				# Thumbnail small images (1: yes, 0: no)
#use constant THUMBNAIL_QUALITY => 70;			# Thumbnail JPEG quality
#use constant ALLOW_TEXTONLY => 1;				# Allow textonly posts (1: yes, 0: no)
#use constant ALLOW_IMAGES => 1;				# Allow image posting (1: yes, 0: no)
#use constant ALLOW_TEXT_REPLIES => 1;			# Allow replies (1: yes, 0: no)
#use constant ALLOW_IMAGE_REPLIES => 1;			# Allow replies with images (1: yes, 0: no)
#use constant ALLOW_UNKNOWN => 0;				# Allow unknown filetypes (1: yes, 0: no)
#use constant MUNGE_UNKNOWN => '.unknown';		# Munge unknown file type extensions with this. If you remove this, make sure your web server is locked down properly.
#use constant FORBIDDEN_EXTENSIONS => ('php','php3','php4','phtml','shtml','cgi','pl','pm','py','r','exe','dll','scr','pif','asp','cfm','jsp','vbs'); # file extensions which are forbidden
#use constant RENZOKU => 5;						# Seconds between posts (floodcheck)
#use constant RENZOKU2 => 10;					# Seconds between image posts (floodcheck)
#use constant RENZOKU3 => 900;					# Seconds between identical posts (floodcheck)
#use constant NOSAGE_WINDOW => 1200;			# Seconds that you can post to your own thread without increasing the sage count
#use constant USE_SECURE_ADMIN => 0;			# Use HTTPS for the admin panel.
#use constant CHARSET => 'utf-8';				# Character set to use, typically 'utf-8' or 'shift_jis'. Disable charset handling by setting to ''. Remember to set Apache to use the same character set for .html files! (AddCharset shift_jis html)
#use constant CONVERT_CHARSETS => 1;			# Do character set conversions internally
#use constant TRIM_METHOD => 0;					# Which threads to trim (0: oldest - like futaba 1: least active - furthest back)
#use constant DATE_STYLE => 'futaba';				# Date style ('futaba', '2ch', 'localtime', 'tiny')
#use constant DISPLAY_ID => 0;					# Display user IDs (0: never, 1: if no email, 2:always)
#use constant EMAIL_ID => 'Heaven';				# ID string to use when DISPLAY_ID is 1 and the user uses an email.
#use constant TRIPKEY => '!';					# this character is displayed before tripcodes
#use constant ENABLE_WAKABAMARK => 1;			# Enable WakabaMark formatting. (0: no, 1: yes)
#use constant APPROX_LINE_LENGTH => 150;		# Approximate line length used by reply abbreviation code to guess at the length of a reply.
#use constant STUPID_THUMBNAILING => 0;			# Bypass thumbnailing code and just use HTML to resize the image. STUPID, wastes bandwidth. (1: enable, 0: disable)
#use constant ALTERNATE_REDIRECT => 0;			# Use alternate redirect method. (Javascript/meta-refresh instead of HTTP forwards. Needed to run on certain servers, like IIS.)
#use constant COOKIE_PATH => 'root';			# Path argument for cookies ('root': cookies apply to all boards on the site, 'current': cookies apply only to this board, 'parent': cookies apply to all boards in the parent directory)

# Internal paths and files - might as well leave this alone.
#use constant IMG_DIR => 'src/';				# Image directory (needs to be writeable by the script)
#use constant THUMB_DIR => 'thumb/';			# Thumbnail directory (needs to be writeable by the script)
#use constant RES_DIR => 'res/';				# Reply cache directory (needs to be writeable by the script)
#use constant HTML_SELF => 'wakaba.html';		# Name of main html file
#use constant JS_FILE => 'wakaba.js';			# location of the js file
#use constant PAGE_EXT => '.html';				# Extension used for board pages after first
#use constant ERRORLOG => '';					# Writes out all errors seen by user, mainly useful for debugging
#use constant CONVERT_COMMAND => 'convert';		# location of the ImageMagick convert command (usually just 'convert', but sometime a full path is needed)
##use constant CONVERT_COMMAND => '/usr/X11R6/bin/convert';
#use constant SPAM_FILE => 'spam.txt';

# Icons for filetypes - file extensions specified here will not be renamed, and will get icons
# (except for the built-in image formats). These example icons can be found in the extras/ directory.
#use constant FILETYPES => (
#   # Audio files
#	mp3 => 'icons/audio-mp3.png',
#	ogg => 'icons/audio-ogg.png',
#	aac => 'icons/audio-aac.png',
#	m4a => 'icons/audio-aac.png',
#	mpc => 'icons/audio-mpc.png',
#	mpp => 'icons/audio-mpp.png',
#	mod => 'icons/audio-mod.png',
#	it => 'icons/audio-it.png',
#	xm => 'icons/audio-xm.png',
#	fla => 'icons/audio-flac.png',
#	flac => 'icons/audio-flac.png',
#	sid => 'icons/audio-sid.png',
#	mo3 => 'icons/audio-mo3.png',
#	spc => 'icons/audio-spc.png',
#	nsf => 'icons/audio-nsf.png',
#	# Archive files
#	zip => 'icons/archive-zip.png',
#	rar => 'icons/archive-rar.png',
#	lzh => 'icons/archive-lzh.png',
#	lha => 'icons/archive-lzh.png',
#	gz => 'icons/archive-gz.png',
#	bz2 => 'icons/archive-bz2.png',
#	'7z' => 'icons/archive-7z.png',
#	# Other files
#	swf => 'icons/flash.png',
#	torrent => 'icons/torrent.png',
#	# To stop Wakaba from renaming image files, put their names in here like this:
#	gif => '.',
#	jpg => '.',
#	png => '.',

#);

# no encoding; # Uncomment this if you uncommented the "use encoding" at the top of the file

1;
