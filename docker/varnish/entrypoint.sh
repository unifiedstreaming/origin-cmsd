#!/usr/bin/env sh

set -e

if [ -z "$LOG_FORMAT" ]
  then
  export LOG_FORMAT="%{Host}i %h %l %u %t \"%r\" %s %b \"%{Referer}i\" \"%{User-agent}i\" \"%{Varnish:hitmiss}x\""
fi



# validate required variables are set

if [ -z "$TARGET_HOST" ]
  then
  echo >&2 "Error: TARGET_HOST environment variable is required but not set."
  exit 1
fi

if [ -z "$TARGET_PORT" ]
  then
  TARGET_PORT=80
fi


if [ -z "$VARNISHNCSA_QUERY" ]
  then
    export VARNISHNCSA_QUERY="ReqURL ne \"<url_which_should_be_not_logged>\""
fi

if [ -z "$VARNISH_VCL" ]
    then
    export VARNISH_VCL="/etc/varnish/default.vcl"
fi

if [ -z "$VARNISH_PORT" ]
    then
    export VARNISH_PORT=80
fi

if [ -z "$VARNISH_RAM_STORAGE" ]
    then 
    export VARNISH_RAM_STORAGE="128M"
fi

if [ -z "${VARNISHD_DEFAULT_OPTS}" ]; then
    VARNISHD_DEFAULT_OPTS="-a :${VARNISH_PORT} -s default=malloc,${VARNISH_RAM_STORAGE}"
fi


VARNISHD_FULL_OPTS="${VARNISHD_OPTS} ${VARNISHD_ADDITIONAL_OPTS} ${VARNISHD_DEFAULT_OPTS} -f /etc/varnish/default.vcl"

# update configuration based on env vars
/bin/sed "s|{{TARGET_HOST}}|${TARGET_HOST}|g; s|{{TARGET_PORT}}|${TARGET_PORT}|g" /etc/varnish/default.vcl.in > /etc/varnish/default.vcl

start_varnishd () {

    VARNISHD="$(command -v varnishd)  \
                    ${VARNISHD_FULL_OPTS}"

    VARNISHD_NCSA="exec $(command -v varnishncsa) \
                    -q '${VARNISHNCSA_QUERY}' -F '${LOG_FORMAT}' -w /var/log/varnish/access.log"

    echo $VARNISHD
    echo $VARNISHD_NCSA

    eval "${VARNISHD}"
    eval "${VARNISHD_NCSA}"

}

start_varnishd
