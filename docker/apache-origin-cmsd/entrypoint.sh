#!/bin/sh
set -e

# set env vars to defaults if not already set
if [ -z "$LOG_LEVEL" ]
  then
  export LOG_LEVEL=warn
fi

if [ -z "$LOG_FORMAT" ]
  then
  export LOG_FORMAT="%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\" %D"
fi


# change Listen 80 to Listen 0.0.0.0:80 to avoid some strange issues when IPv6 is available
/bin/sed -i "s@Listen 80@Listen 0.0.0.0:80@g" /etc/apache2/httpd.conf

# change mpm_prefork_module to mpm_worker_module
/bin/sed -i "s@LoadModule mpm_prefork_module modules/mod_mpm_prefork.so@LoadModule mpm_worker_module modules/mod_mpm_worker.so@g" /etc/apache2/httpd.conf


rm -f /run/apache2/httpd.pid

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
  set -- httpd $EXTRA_OPTIONS "$@"
fi

exec "$@"