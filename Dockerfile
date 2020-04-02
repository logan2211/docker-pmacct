FROM debian:stable as build

ARG PMACCT_VERSION=master
ARG BUILD_WORKERS=8

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        bison \
        build-essential \
        curl \
        flex \
        libreadline-dev \
        libncurses5-dev \
        m4 \
        libpcap-dev \
        libtool \
        automake1.1 \
        autoconf2.13 \
        pkg-config \
        libjansson-dev \
        libsqlite3-dev \
        libmaxminddb-dev \
        default-libmysqlclient-dev && \
    rm -rf /var/lib/apt/lists/* && \
    cd /tmp && \
    curl -LO https://github.com/pmacct/pmacct/archive/${PMACCT_VERSION}.tar.gz && \
    tar -xzf ${PMACCT_VERSION}.tar.gz && \
    mkdir /tmp/target && \
    cd pmacct-${PMACCT_VERSION} && \
    ./autogen.sh && \
    ./configure \
        --prefix=/tmp/target \
        --enable-jansson \
        --enable-mysql \
        --enable-sqlite3 \
        --enable-geoipv2 && \
    make -j${BUILD_WORKERS} && \
    make install && \
    make clean

FROM debian:stable as final

LABEL maintainer="Logan V. <logan2211@gmail.com>"

ENV DEBIAN_FRONTEND noninteractive

ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

RUN apt-get update && apt-get install -y --no-install-recommends \
        libncurses5 \
        libpcap0.8 \
        libjansson4 \
        libsqlite3-0 \
        libmaxminddb0 \
        default-libmysqlclient-dev && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir /etc/pmacct

COPY --from=build /tmp/target /usr/local

RUN ldconfig

ENTRYPOINT ["/tini", "--"]
CMD ["pmacctd", "-f", "/etc/pmacct/pmacctd.conf"]
