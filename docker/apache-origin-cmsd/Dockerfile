ARG ALPINEVERSION=3.14

FROM alpine:$ALPINEVERSION

# ARGs declared before FROM are in a different scope, so need to be stated again
# https://docs.docker.com/engine/reference/builder/#understand-how-arg-and-from-interact
ARG ALPINEVERSION

RUN apk \
    --update \
    --repository $REPO/v$ALPINEVERSION \
    add \
        apache2 \
        apache2-proxy \
        apache2-ssl \
        python3 \
        py3-pip \
&&  rm -f /var/cache/apk/*


# Set up directories and log file redirection
RUN mkdir -p /run/apache2 \
    && ln -s /dev/stderr /var/log/apache2/error.log \
    && ln -s /dev/stdout /var/log/apache2/access.log \
    && mkdir -p /var/www/origin \
    && mkdir -p /var/cache/httpd \
    && mkdir -p /var/httpd/locks \
    && rm -f /etc/apache2/conf.d/*

# Copy apache config and entrypoint script
COPY conf.d /etc/apache2/conf.d
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh

# Copy webpage
COPY html /var/www/origin/
RUN chmod -R 777 /var/www/origin/

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["-D", "FOREGROUND"]

