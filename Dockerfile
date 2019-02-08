FROM debian:jessie-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    cmake \
    curl \
    gettext \
    libboost-system-dev \
    libbz2-dev \
    libssl-dev \
    pkg-config

# eiskaltdcpp
RUN curl -L https://github.com/eiskaltdcpp/eiskaltdcpp/archive/master.tar.gz | tar xz -C /tmp
RUN mkdir -p /tmp/eiskaltdcpp-master/builddir
RUN cd /tmp/eiskaltdcpp-master/builddir \
 && cmake -DCMAKE_BUILD_TYPE=Release \
          -DLUA_SCRIPT=OFF \
          -DUSE_MINIUPNP=OFF \
          -DPERL_REGEX=OFF \
          -DNO_UI_DAEMON=ON \
          -DJSONRPC_DAEMON=ON \
          -DLOCAL_JSONCPP=ON \
          -DUSE_QT=OFF \
          -DUSE_QT5=OFF \
          -DUSE_IDNA=OFF \
          -DFREE_SPACE_BAR_C=OFF \
          -DLINK=STATIC \
          -Dlinguas="" \
          ..
RUN cd /tmp/eiskaltdcpp-master/builddir \
 && make
 
 

# icecult + webserver
RUN curl -L https://github.com/eiskaltdcpp/eiskaltdcpp-web/archive/master.tar.gz | tar xz -C /tmp
RUN curl -L https://github.com/kraiz/icecult/archive/master.tar.gz | tar xz -C /tmp
RUN curl -L https://caddyserver.com/download/linux/amd64?license=personal | tar xz -C /bin
# forego - process manager
RUN curl https://bin.equinox.io/c/ekMN3bCZFUn/forego-stable-linux-amd64.tgz | tar xz -C /bin


# -----------------------------------------------------------------------------
# production image:
# -----------------------------------------------------------------------------
FROM debian:jessie-slim
COPY --from=builder /tmp/eiskaltdcpp-master/builddir/eiskaltdcpp-daemon/eiskaltdcpp-daemon \
                    /bin/forego \
                    /bin/caddy \
                    /bin/
COPY --from=builder /tmp/icecult-master/app /opt/icecult
COPY --from=builder /tmp/eiskaltdcpp-web-master /opt/eiskaltdcpp-web

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    iproute2 \
    libboost-system1.55.0

ADD ./Procfile /
ADD ./Caddyfile /

EXPOSE 80/tcp 7000/udp 1080/tcp

CMD ["/bin/forego", "start"]
