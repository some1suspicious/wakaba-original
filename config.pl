# use encoding 'shift-jis'; # Uncomment this to use shift-jis in strings. ALSO uncomment the "no encoding" at the end of the file!

# System config
use constant ADMIN_PASS => 'CHANGEME';		# Admin password. For fucks's sake, change this.
use constant SECRET => 'CHANGEME';	# Cryptographic secret. CHANGE THIS to something totally random, and long.

# Page look
use constant TITLE => 'Wakaba image board';	# Name of this image board
use constant SHOWTITLETXT => 1;			# Show TITLE at top (1: yes  0: no)
use constant SHOWTITLEIMG => 0;			# Show image at top (0: no, 1: single, 2: rotating)
use constant TITLEIMG => 'title.jpg';		# Title image (point to php file if rotating)
use constant FAVICON => '';			# Favicon.ico file
use constant THREADS_PER_PAGE => 10;		# Threads per page
use constant REPLIES_PER_THREAD => 10;           # Replies shown
use constant S_ANONAME => 'Anonymous';			# Defines what to print if there is no text entered in the name field
use constant S_ANOTEXT => '';				# Defines what to print if there is no text entered in the comment field
use constant S_ANOTITLE => '';			# Defines what to print if there is no text entered into subject field

# Limitations
use constant MAX_KB => 1000;			# Maximum upload size in KB
use constant MAX_W => 200;			# Images exceeding this width will be thumbnailed
use constant MAX_H => 200;			# Images exceeding this height will be thumbnailed
use constant MAX_RES => 20;			# Maximum topic bumps
use constant MAX_THREADS => 100;			# Maximum number of threads
use constant MAX_FIELD_LENGTH => 100;	# Maximum number of characters in subject, name, and email
use constant MAX_COMMENT_LENGTH => 1000;	# Maximum number of characters in a comment
use constant MAX_LINES => 15;			# Max lines per post (0 = no limit)
use constant MAX_IMAGE_WIDTH => 16384;		# Maximum width of image before rejecting
use constant MAX_IMAGE_HEIGHT => 16384;		# Maximum height of image before rejecting
use constant MAX_IMAGE_PIXELS => 50000000;	# Maximum width*height of image before rejecting
use constant MAX_KEY_LOG => 1000;		# Number of captcha keys to log

# Captcha
use constant ENABLE_CAPTCHA => 1;

# Tweaks
use constant THUMBNAIL_SMALL => 1;		# Thumbnail small images (1: yes, 0: no)
use constant THUMBNAIL_QUALITY => 70;	# Thumbnail JPEG quality
use constant ALLOW_UNKNOWN => 0;		# Allow unknown filetypes (1: yes, 0: no)
use constant MUNGE_UNKNOWN => '.unknown';	# Munge unknown file type extensions with this. If you remove this, make sure your web server is locked down properly.
use constant FORBIDDEN_EXTENSIONS => ('php','php3','php4','phtml','shtml','cgi','pl','pm','py','r','exe','dll','scr','pif','asp','cfm','jsp'); # file extensions which are forbidden
use constant PROXY_CHECK => ();		# Ports to scan for proxies - NOT IMPLEMENTED.
use constant CHARSET => 'utf-8';		# Character set to use, typically "utf-8" or "shift_jis". Remember to set Apache to use the same character set for .html files! (AddCharset shift_jis html)
use constant TRIM_METHOD => 1;			# Which threads to trim (0: oldest - like futaba 1: least active - furthest back)
use constant DATE_STYLE => 0;			# Date style (0: futaba 1: localtime)
use constant DISPLAY_ID => 1;			# Display user IDs (0: never, 1: if no email, 2:always)
use constant EMAIL_ID => 'Heaven';		# ID string to use when DISPLAY_ID is 1 and the user uses an email.
use constant TRIPKEY => '!';			# this character is displayed before tripcodes

# Internal paths and files - might as well leave this alone.
use constant IMG_DIR => 'src/';			# Image directory (needs to be writeable by the script)
use constant THUMB_DIR => 'thumb/';		# Thumbnail directory (needs to be writeable by the script)
use constant RES_DIR => 'res/';			# Reply cache directory (needs to be writeable by the script)
use constant HTML_SELF => 'wakaba.html';	# Name of main html file
use constant PAGE_EXT => '.html';		# Extension used for board pages after first
use constant CONVERT_COMMAND => 'convert';	# location of the ImageMagick convert command (usually just 'convert', but sometime a full path is needed)
#use constant CONVERT_COMMAND => '/usr/X11R6/bin/convert';

# no encoding; # Uncomment this if you uncommented the "use encoding" at the top of the file

1;
