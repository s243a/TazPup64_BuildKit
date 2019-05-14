#!/bin/sh
#
# help.cgi - Display TazPanel doc and README.
#
# Copyright (C) 2011-2015 SliTaz GNU/Linux - BSD License
#
# Modified by mistfire for TazPuppy


. ./lib/libtazpanel
get_config
header
search_form() {
cat <<EOT
<form class="search"><!--
--><input type="search" name="manual" results="5" autosave="pkgsearch" autocomplete="on"><!--
--><button type="submit">$(_ 'Manual')</button><!--
--></form>
EOT
}
TITLE=$(_ 'Help Doc')
xhtml_header
search_form
if [ -n "$(GET manual)" ]; then
echo "<pre>"
man $(GET manual)
echo "</pre>"
else
for i in doc/tazpanel $PANEL/README ; do
cat $i.${LANG%_*}.html 2> /dev/null || cat $i.html
done
fi
xhtml_footer
exit 0
