ARG NGINXVERSION=1.21.4-alpine

FROM nginx:$NGINXVERSION

COPY conf/http/cmsd.nginx.conf.in /etc/nginx/nginx.conf.in
COPY nginx-logs.conf.in /etc/nginx/nginx-logs.conf
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh

# Remove symlinks that are created by defaut to save logs in host's disk
# RUN unlink /dev/stdout
# RUN unlink /dev/stderr


EXPOSE 80

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["-g", "daemon off;"]
