#!/bin/bash
src=/opt/test/
/usr/local/bin/inotifywait -mrq --timefmt '%d/%m/%y %H:%M' --format '%T %w%f%e' -e close_write,delete,create,attrib $src |while read file
do
    /usr/bin/rsync -arzuq $src 10.200.11.143::www/
    echo "  ${file} was rsynced" >>/opt/soft/log/rsync.log 2>&1
done
