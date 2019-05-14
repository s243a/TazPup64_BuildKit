#!/bin/sh
#Force update cache files
#written by mistfire

GTKVERLIST='2.0 3.0'

glib-compile-schemas /usr/share/glib-2.0/schemas 2>/dev/null
gio-querymodules /usr/lib/gio/modules	
gdk-pixbuf-query-loaders --update-cache
pango-querymodules --update-cache
iconvconfig 2>/dev/null

for gtkver in $GTKVERLIST
do
 if [ "$(which gtk-query-immodules-$gtkver)" != "" ]; then 
  gtk-query-immodules-$gtkver --update-cache
 fi
done

fc-cache -f
update-desktop-database /usr/share/applications
update-mime-database /usr/share/mime
gtk-update-icon-cache /usr/share/icons/hicolor

depmod -a
