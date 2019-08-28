use strict;

BEGIN {
	use constant S_NOADMIN => 'No ADMIN_PASS or NUKE_PASS defined in the configuration';	# Returns error when the config is incomplete
	use constant S_NOSECRET => 'No SECRET defined in the configuration';		# Returns error when the config is incomplete
	use constant S_NOSQL => 'No SQL settings defined in the configuration';		# Returns error when the config is incomplete

	die S_NOADMIN unless(defined &ADMIN_PASS);
	die S_NOADMIN unless(defined &NUKE_PASS);
	die S_NOSECRET unless(defined &SECRET);
	die S_NOSQL unless(defined &SQL_DBI_SOURCE);
	die S_NOSQL unless(defined &SQL_USERNAME);
	die S_NOSQL unless(defined &SQL_PASSWORD);

	eval "use constant SQL_TABLE => 'comments'" unless(defined &SQL_TABLE);
	eval "use constant SQL_ADMIN_TABLE => 'admin'" unless(defined &SQL_ADMIN_TABLE);
	eval "use constant USE_TEMPFILES => 1" unless(defined &USE_TEMPFILES);

	eval "use constant TITLE => 'Wakaba image board'" unless(defined &TITLE);
	eval "use constant SHOWTITLETXT => 1" unless(defined &SHOWTITLETXT);
	eval "use constant SHOWTITLEIMG => 0" unless(defined &SHOWTITLEIMG);
	eval "use constant TITLEIMG => 'title.jpg'" unless(defined &TITLEIMG);
	eval "use constant FAVICON => 'wakaba.ico'" unless(defined &FAVICON);
	eval "use constant HOME => '../'" unless(defined &HOME);
	eval "use constant IMAGES_PER_PAGE => 10" unless(defined &IMAGES_PER_PAGE);
	eval "use constant REPLIES_PER_THREAD => 10" unless(defined &REPLIES_PER_THREAD);
	eval "use constant IMAGE_REPLIES_PER_THREAD => 0" unless(defined &IMAGE_REPLIES_PER_THREAD);
	eval "use constant S_ANONAME => 'Anonymous'" unless(defined &S_ANONAME);
	eval "use constant S_ANOTEXT => ''" unless(defined &S_ANOTEXT);
	eval "use constant S_ANOTITLE => ''" unless(defined &S_ANOTITLE);
	eval "use constant DEFAULT_STYLE => 'Futaba'" unless(defined &DEFAULT_STYLE);

	eval "use constant MAX_KB => 1000" unless(defined &MAX_KB);
	eval "use constant MAX_W => 200" unless(defined &MAX_W);
	eval "use constant MAX_H => 200" unless(defined &MAX_H);
	eval "use constant MAX_RES => 20" unless(defined &MAX_RES);
	eval "use constant MAX_POSTS => 500" unless(defined &MAX_POSTS);
	eval "use constant MAX_THREADS => 0" unless(defined &MAX_THREADS);
	eval "use constant MAX_AGE => 0" unless(defined &MAX_AGE);
	eval "use constant MAX_FIELD_LENGTH => 100" unless(defined &MAX_FIELD_LENGTH);
	eval "use constant MAX_COMMENT_LENGTH => 8192" unless(defined &MAX_COMMENT_LENGTH);
	eval "use constant MAX_LINES_SHOWN => 15" unless(defined &MAX_LINES_SHOWN);
	eval "use constant MAX_IMAGE_WIDTH => 16384" unless(defined &MAX_IMAGE_WIDTH);
	eval "use constant MAX_IMAGE_HEIGHT => 16384" unless(defined &MAX_IMAGE_HEIGHT);
	eval "use constant MAX_IMAGE_PIXELS => 50000000" unless(defined &MAX_IMAGE_PIXELS);

	eval "use constant ENABLE_CAPTCHA => 1" unless(defined &ENABLE_CAPTCHA);
	eval "use constant SQL_CAPTCHA_TABLE => 'captcha'" unless(defined &SQL_CAPTCHA_TABLE);
	eval "use constant CAPTCHA_LIFETIME => 1440" unless(defined &CAPTCHA_LIFETIME);
	eval "use constant CAPTCHA_SCRIPT => 'captcha.pl'" unless(defined &CAPTCHA_SCRIPT);
	eval "use constant CAPTCHA_HEIGHT => 18" unless(defined &CAPTCHA_HEIGHT);
	eval "use constant CAPTCHA_SCRIBBLE => 0.2" unless(defined &CAPTCHA_SCRIBBLE);
	eval "use constant CAPTCHA_SCALING => 0.15" unless(defined &CAPTCHA_SCALING);
	eval "use constant CAPTCHA_ROTATION => 0.3" unless(defined &CAPTCHA_ROTATION);
	eval "use constant CAPTCHA_SPACING => 2.5" unless(defined &CAPTCHA_SPACING);

	eval "use constant THUMBNAIL_SMALL => 1" unless(defined &THUMBNAIL_SMALL);
	eval "use constant THUMBNAIL_QUALITY => 70" unless(defined &THUMBNAIL_QUALITY);
	eval "use constant ALLOW_TEXTONLY => 1" unless(defined &ALLOW_TEXTONLY);
	eval "use constant ALLOW_IMAGES => 1" unless(defined &ALLOW_IMAGES);
	eval "use constant ALLOW_TEXT_REPLIES => 1" unless(defined &ALLOW_TEXT_REPLIES);
	eval "use constant ALLOW_IMAGE_REPLIES => 1" unless(defined &ALLOW_IMAGE_REPLIES);
	eval "use constant ALLOW_UNKNOWN => 0" unless(defined &ALLOW_UNKNOWN);
	eval "use constant MUNGE_UNKNOWN => '.unknown'" unless(defined &MUNGE_UNKNOWN);
	eval "use constant FORBIDDEN_EXTENSIONS => ('php','php3','php4','phtml','shtml','cgi','pl','pm','py','r','exe','dll','scr','pif','asp','cfm','jsp')" unless(defined &FORBIDDEN_EXTENSIONS);
	eval "use constant RENZOKU => 5" unless(defined &RENZOKU);
	eval "use constant RENZOKU2 => 10" unless(defined &RENZOKU2);
	eval "use constant RENZOKU3 => 900" unless(defined &RENZOKU3);
	eval "use constant NOSAGE_WINDOW => 1200" unless(defined &NOSAGE_WINDOW);
	eval "use constant PROXY_CHECK => ()" unless(defined &PROXY_CHECK);
	eval "use constant USE_SECURE_ADMIN => 0" unless(defined &USE_SECURE_ADMIN);
	eval "use constant CHARSET => 'utf-8'" unless(defined &CHARSET);
	eval "use constant CONVERT_CHARSETS => 1" unless(defined &CONVERT_CHARSETS);
	eval "use constant TRIM_METHOD => 0" unless(defined &TRIM_METHOD);
	eval "use constant DATE_STYLE => 'futaba'" unless(defined &DATE_STYLE);
	eval "use constant DISPLAY_ID => 0" unless(defined &DISPLAY_ID);
	eval "use constant EMAIL_ID => 'Heaven'" unless(defined &EMAIL_ID);
	eval "use constant TRIPKEY => '!'" unless(defined &TRIPKEY);
	eval "use constant ENABLE_WAKABAMARK => 1" unless(defined &ENABLE_WAKABAMARK);
	eval "use constant APPROX_LINE_LENGTH => 150" unless(defined &APPROX_LINE_LENGTH);
	eval "use constant STUPID_THUMBNAILING => 0" unless(defined &STUPID_THUMBNAILING);
	eval "use constant ALTERNATE_REDIRECT => 0" unless(defined &ALTERNATE_REDIRECT);
	eval "use constant COOKIE_PATH => 'root'" unless(defined &COOKIE_PATH);
	eval "use constant STYLE_COOKIE => 'wakabastyle'" unless(defined &STYLE_COOKIE);

	eval "use constant IMG_DIR => 'src/'" unless(defined &IMG_DIR);
	eval "use constant THUMB_DIR => 'thumb/'" unless(defined &THUMB_DIR);
	eval "use constant RES_DIR => 'res/'" unless(defined &RES_DIR);
	eval "use constant HTML_SELF => 'wakaba.html'" unless(defined &HTML_SELF);
	eval "use constant JS_FILE => 'wakaba.js'" unless(defined &JS_FILE);
	eval "use constant CSS_DIR => 'css/'" unless(defined &CSS_DIR);
	eval "use constant PAGE_EXT => '.html'" unless(defined &PAGE_EXT);
	eval "use constant ERRORLOG => ''" unless(defined &ERRORLOG);
	eval "use constant CONVERT_COMMAND => 'convert'" unless(defined &CONVERT_COMMAND);
	eval "use constant SPAM_FILE => 'spam.txt'" unless(defined &SPAM_FILE);

	eval "use constant FILETYPES => ()" unless(defined &FILETYPES);

	eval "use constant WAKABA_VERSION => '2.0.6'" unless(defined &WAKABA_VERSION);
}

1;
