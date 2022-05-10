#!/bin/sh

# set env vars or defaults
if [ -z "$LOG_LEVEL" ]
  then
  export LOG_LEVEL=warn
fi


# validate required variables are set
if [ -z "$TARGET" ]
  then
  echo >&2 "Error: TARGET environment variable is required but not set."
  exit 1
fi

if [ -z "$UPSTREAM" ]
  then
  export UPSTREAM=$TARGET
fi

# update configuration based on env vars
/bin/sed "s|{{LOG_LEVEL}}|${LOG_LEVEL}|g; s|{{LOG_FORMAT}}|${LOG_FORMAT}|g; s|{{NAME}}|${NAME}|g; s|{{TARGET}}|${TARGET}|g; s|{{UPSTREAM}}|${UPSTREAM}|g; s|{{CACHE_KEY}}|${CACHE_KEY}|g" /etc/nginx/nginx.conf.in > /etc/nginx/nginx.conf

rm -f /run/nginx/nginx.pid

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
  set -- nginx "$@"
fi

exec "$@"
