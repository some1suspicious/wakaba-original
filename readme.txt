Welcome to Wakaba, pre-release version.

There's no proper documentation yet.

The script behaves a lot like futaba (http://www.2chan.net/script/) or 
futallaby (http://www.1chan.net/futallaby/). I stole most of the
translations from futallaby. Many thanks to thatdog for his work on that.

The script lives in a directory that needs to be writable by the web
server process. This might mean you need to set it to full permission,
777. It wants three subdirectories, src, thumb and res, and those need
to be writeable too.

Edit the config.pl files according to your needs. You should at least
configure the admin password and SQL settings.

For SQL backends, the script has been designed to be able to use either
mysql or sqlite. You'll need to install Perl drivers for the one you
choose. I've tried to keep down the number of external dependecies as
much as possible, but there are a few:

For thumbnailing, it tries, in this order, the PerlMagick module, the
external ImageMagick "convert" command, and finally the netpbm tools.
It also either needs the Digest::MD5 module, which is standard in
newer Perl versions but not in older, or the external "md5sum"
command. To make charset conversion work properly, you need Perl 5.8.0
or higher. On older perl versions, it tries to work entirely in ISO
Latin-1, but this is untested, like much else. Furthermore, you
should make your webserver send the proper charset code for the
pages the script creates. With Apache, make a .htaccess files with
"AddCharset utf-8 .html" in it.

When the script is run the first time, it tries to create its
databases, and make the first HTML page. Hopefully this works,
otherwise you might need to mess around with it in uncomfortable ways.
The admin interface as an option to re-make all the static HTML pages,
which is necessary if the script is moved, or if you change options in
the config file that affect the pages directly. If everything breaks
and you can't get to the admin interface, try accessing
http://.../wakaba.pl?action=rebuild&admin=ADMINPASSWORD

Well, good luck. Report problems and bugs to me at paracelsus@gmail.com.

- !WAHa.06x36
