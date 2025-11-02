# ---- Git Clone Stage ----
FROM alpine:3.22 AS git-clone

ARG RATHENA_REF=master

RUN apk add --no-cache git ca-certificates
RUN git clone --depth=1 --branch "${RATHENA_REF}" https://github.com/rathena/rathena.git /src/rathena

# ---- Build Stage ----
FROM alpine:3.22 AS build

ARG RATHENA_PACKETVER=20220406

RUN apk add --no-cache wget cmake make gcc g++ gdb zlib-dev mariadb-dev ca-certificates linux-headers bash valgrind netcat-openbsd

COPY --from=git-clone /src/rathena /src/rathena

WORKDIR /src/rathena
RUN ./configure --enable-packetver=${RATHENA_PACKETVER} --enable-vip && make clean && make all && yes | ./yaml2sql

# ---- Runtime ----
FROM alpine:3.22 as runtime
WORKDIR /rathena

RUN apk add --no-cache libgcc libstdc++ zlib mariadb-connector-c

COPY --chown=root:root entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

RUN addgroup -g 1000 rathena && \
    adduser -D -u 1000 -G rathena -h /rathena -s /bin/sh rathena
USER rathena

COPY --from=git-clone --chown=rathena:rathena /src/rathena/ /rathena/
COPY --from=build --chown=rathena:rathena /src/rathena/conf/import /rathena/conf/import
COPY --from=build --chown=rathena:rathena /src/rathena/conf/msg_conf/import /rathena/conf/msg_conf/import
COPY --from=build --chown=rathena:rathena /src/rathena/db/import /rathena/db/import

# ---- Final Stage - Login Server ----
FROM runtime AS login-server
COPY --from=build --chown=rathena:rathena /src/rathena/login-server /rathena/login-server
EXPOSE 6900 6121 5121 8888
ENV MODE=login
ENTRYPOINT ["/entrypoint.sh"]


# ---- Final Stage - Char Server ----
FROM runtime AS char-server
COPY --from=build --chown=rathena:rathena /src/rathena/char-server  /rathena/char-server
EXPOSE 6900 6121 5121 8888
ENV MODE=char
ENTRYPOINT ["/entrypoint.sh"]


# ---- Final Stage - Map Server ----
FROM runtime AS map-server
COPY --from=build --chown=rathena:rathena /src/rathena/map-server   /rathena/map-server
EXPOSE 6900 6121 5121 8888
ENV MODE=map
ENTRYPOINT ["/entrypoint.sh"]


# ---- Final Stage - Web Server ----
FROM runtime AS web-server
COPY --from=build --chown=rathena:rathena /src/rathena/web-server   /rathena/web-server
EXPOSE 6900 6121 5121 8888
ENV MODE=web
ENTRYPOINT ["/entrypoint.sh"]


# ---- Final Stage - All ----
FROM runtime AS all
COPY --from=build --chown=rathena:rathena /src/rathena/login-server /rathena/login-server
COPY --from=build --chown=rathena:rathena /src/rathena/char-server  /rathena/char-server
COPY --from=build --chown=rathena:rathena /src/rathena/map-server   /rathena/map-server
COPY --from=build --chown=rathena:rathena /src/rathena/web-server   /rathena/web-server
COPY --from=build --chown=rathena:rathena /src/rathena/sql-files /rathena/sql-files
COPY --from=build --chown=rathena:rathena /src/rathena/mapcache /rathena/mapcache
COPY --from=build --chown=rathena:rathena /src/rathena/csv2yaml /rathena/csv2yaml
COPY --from=build --chown=rathena:rathena /src/rathena/yaml2sql /rathena/yaml2sql
COPY --from=build --chown=rathena:rathena /src/rathena/yamlupgrade /rathena/yamlupgrade
COPY --from=build --chown=rathena:rathena /src/rathena/map-server-generator /rathena/map-server-generator
ENV MODE=all
ENTRYPOINT ["/entrypoint.sh"]




