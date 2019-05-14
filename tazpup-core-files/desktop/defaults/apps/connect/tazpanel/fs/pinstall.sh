#!/bin/sh

sed -i -e "s#\
<icon x=\"32\" y=\"416\" label=\"connect\">\/usr\/local\/apps\/Connect<\/icon>#\
<icon x=\"32\" y=\"416\" label=\"connect\">\/usr\/local\/bin\/defaultconnect<\/icon>#g" \
/root/Choices/ROX-Filer/globicons

