use strict;

BEGIN {
	sub declared($)
	{
		use constant 1.01; # don't omit this! ...tte iu no ka
		return $constant::declared{"main::".shift};
	}

	use constant S_NOADMIN => 'No ADMIN_PASS or NUKE_PASS defined in the configuration';	# Returns error when the config is incomplete
	use constant S_NOSECRET => 'No SECRET defined in the configuration';		# Returns error when the config is incomplete
	use constant S_NOSQL => 'No SQL settings defined in the configuration';		# Returns error when the config is incomplete

	make_error(S_NOADMIN) unless(declared("ADMIN_PASS"));
	make_error(S_NOADMIN) unless(declared("NUKE_PASS"));
	make_error(S_NOSECRET) unless(declared("SECRET"));
	make_error(S_NOSQL) unless(declared("SQL_DBI_SOURCE"));
	make_error(S_NOSQL) unless(declared("SQL_USERNAME"));
	make_error(S_NOSQL) unless(declared("SQL_PASSWORD"));

	eval "use constant SQL_TABLE => 'comments'" unless(declared("SQL_TABLE"));
	eval "use constant SQL_ADMIN_TABLE => 'admin'" unless(declared("SQL_ADMIN_TABLE"));
	eval "use constant USE_TEMPFILES => 1" unless(declared("USE_TEMPFILES"));

	eval "use constant TITLE => 'Wakaba image board'" unless(declared("TITLE"));
	eval "use constant SHOWTITLETXT => 1" unless(declared("SHOWTITLETXT"));
	eval "use constant SHOWTITLEIMG => 0" unless(declared("SHOWTITLEIMG"));
	eval "use constant TITLEIMG => 'title.jpg'" unless(declared("TITLEIMG"));
	eval "use constant FAVICON => 'wakaba.ico'" unless(declared("FAVICON"));
	eval "use constant HOME => '../'" unless(declared("HOME"));
	eval "use constant IMAGES_PER_PAGE => 10" unless(declared("IMAGES_PER_PAGE"));
	eval "use constant REPLIES_PER_THREAD => 10" unless(declared("REPLIES_PER_THREAD"));
	eval "use constant S_ANONAME => 'Anonymous'" unless(declared("S_ANONAME"));
	eval "use constant S_ANOTEXT => ''" unless(declared("S_ANOTEXT"));
	eval "use constant S_ANOTITLE => ''" unless(declared("S_ANOTITLE"));
	eval "use constant DEFAULT_STYLE => 'Futaba'" unless(declared("DEFAULT_STYLE"));

	eval "use constant MAX_KB => 1000" unless(declared("MAX_KB"));
	eval "use constant MAX_W => 200" unless(declared("MAX_W"));
	eval "use constant MAX_H => 200" unless(declared("MAX_H"));
	eval "use constant MAX_RES => 20" unless(declared("MAX_RES"));
	eval "use constant MAX_POSTS => 500" unless(declared("MAX_POSTS"));
	eval "use constant MAX_THREADS => 0" unless(declared("MAX_THREADS"));
	eval "use constant MAX_AGE => 0" unless(declared("MAX_AGE"));
	eval "use constant MAX_FIELD_LENGTH => 100" unless(declared("MAX_FIELD_LENGTH"));
	eval "use constant MAX_COMMENT_LENGTH => 8192" unless(declared("MAX_COMMENT_LENGTH"));
	eval "use constant MAX_LINES_SHOWN => 15" unless(declared("MAX_LINES_SHOWN"));
	eval "use constant MAX_IMAGE_WIDTH => 16384" unless(declared("MAX_IMAGE_WIDTH"));
	eval "use constant MAX_IMAGE_HEIGHT => 16384" unless(declared("MAX_IMAGE_HEIGHT"));
	eval "use constant MAX_IMAGE_PIXELS => 50000000" unless(declared("MAX_IMAGE_PIXELS"));

	eval "use constant ENABLE_CAPTCHA => 1" unless(declared("ENABLE_CAPTCHA"));
	eval "use constant SQL_CAPTCHA_TABLE => 'captcha'" unless(declared("SQL_CAPTCHA_TABLE"));
	eval "use constant CAPTCHA_LIFETIME => 1440" unless(declared("CAPTCHA_LIFETIME"));
	eval "use constant CAPTCHA_SCRIPT => 'captcha.pl'" unless(declared("CAPTCHA_SCRIPT"));

	eval "use constant THUMBNAIL_SMALL => 1" unless(declared("THUMBNAIL_SMALL"));
	eval "use constant THUMBNAIL_QUALITY => 70" unless(declared("THUMBNAIL_QUALITY"));
	eval "use constant ALLOW_TEXTONLY => 1" unless(declared("ALLOW_TEXTONLY"));
	eval "use constant ALLOW_IMAGES => 1" unless(declared("ALLOW_IMAGES"));
	eval "use constant ALLOW_TEXT_REPLIES => 1" unless(declared("ALLOW_TEXT_REPLIES"));
	eval "use constant ALLOW_IMAGE_REPLIES => 1" unless(declared("ALLOW_IMAGE_REPLIES"));
	eval "use constant ALLOW_UNKNOWN => 0" unless(declared("ALLOW_UNKNOWN"));
	eval "use constant MUNGE_UNKNOWN => '.unknown'" unless(declared("MUNGE_UNKNOWN"));
	eval "use constant FORBIDDEN_EXTENSIONS => ('php','php3','php4','phtml','shtml','cgi','pl','pm','py','r','exe','dll','scr','pif','asp','cfm','jsp')" unless(declared("FORBIDDEN_EXTENSIONS"));
	eval "use constant HIDE_IMAGE_REPLIES => 0" unless(declared("HIDE_IMAGE_REPLIES"));
	eval "use constant RENZOKU => 5" unless(declared("RENZOKU"));
	eval "use constant RENZOKU2 => 10" unless(declared("RENZOKU2"));
	eval "use constant RENZOKU3 => 900" unless(declared("RENZOKU3"));
	eval "use constant NOSAGE_WINDOW => 1200" unless(declared("NOSAGE_WINDOW"));
	eval "use constant PROXY_CHECK => ()" unless(declared("PROXY_CHECK"));
	eval "use constant USE_SECURE_ADMIN => 0" unless(declared("USE_SECURE_ADMIN"));
	eval "use constant CHARSET => 'utf-8'" unless(declared("CHARSET"));
	eval "use constant TRIM_METHOD => 0" unless(declared("TRIM_METHOD"));
	eval "use constant DATE_STYLE => 0" unless(declared("DATE_STYLE"));
	eval "use constant DISPLAY_ID => 0" unless(declared("DISPLAY_ID"));
	eval "use constant EMAIL_ID => 'Heaven'" unless(declared("EMAIL_ID"));
	eval "use constant TRIPKEY => '!'" unless(declared("TRIPKEY"));
	eval "use constant ENABLE_WAKABAMARK => 1" unless(declared("ENABLE_WAKABAMARK"));
	eval "use constant APPROX_LINE_LENGTH => 150" unless(declared("APPROX_LINE_LENGTH"));
	eval "use constant STUPID_THUMBNAILING => 0" unless(declared("STUPID_THUMBNAILING"));
	eval "use constant ALTERNATE_REDIRECT => 0" unless(declared("ALTERNATE_REDIRECT"));

	eval "use constant IMG_DIR => 'src/'" unless(declared("IMG_DIR"));
	eval "use constant THUMB_DIR => 'thumb/'" unless(declared("THUMB_DIR"));
	eval "use constant RES_DIR => 'res/'" unless(declared("RES_DIR"));
	eval "use constant HTML_SELF => 'wakaba.html'" unless(declared("HTML_SELF"));
	eval "use constant CSS_FILE => 'wakaba.css'" unless(declared("CSS_FILE"));
	eval "use constant JS_FILE => 'wakaba.js'" unless(declared("JS_FILE"));
	eval "use constant CSS_DIR => 'css/'" unless(declared("CSS_DIR"));
	eval "use constant PAGE_EXT => '.html'" unless(declared("PAGE_EXT"));
	eval "use constant ERRORLOG => ''" unless(declared("ERRORLOG"));
	eval "use constant CONVERT_COMMAND => 'convert'" unless(declared("CONVERT_COMMAND"));
}

1;
