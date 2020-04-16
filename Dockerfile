FROM alpine:latest
MAINTAINER Francesco Colista <fcolista@alpinelinux.org>
COPY ./start.sh /usr/local/bin/start.sh
ENV PATH=$PATH:/usr/share/metasploit-framework
RUN chmod +x /usr/local/bin/start.sh && \
	echo "http://dl-cdn.alpinelinux.org/alpine/v3.11/community" >> /etc/apk/repositories && \
	echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
        apk add -U --no-cache \
        build-base \
        ruby \
        ruby-bigdecimal \
        ruby-bundler \
        ruby-io-console \
        ruby-webrick \
        ruby-dev \
        libffi-dev\
        openssl-dev \
        readline-dev \
        sqlite-dev \
        postgresql-dev \
        libpcap-dev \
        libxml2-dev \
        libxslt-dev \
        yaml-dev \
        zlib-dev \
        ncurses-dev \
        autoconf \
        bison \
        subversion \
        git \
        sqlite \
        nmap \
        libxslt \
        postgresql \
        ncurses

RUN cd /usr/share && \
        git clone https://github.com/rapid7/metasploit-framework.git && \
        cd /usr/share/metasploit-framework && \
        /usr/bin/bundle update --bundler && \
        /usr/bin/bundle install

RUN apk del \
	build-base \
	ruby-dev \
	libffi-dev\
        libressl-dev \
	readline-dev \
	sqlite-dev \
	postgresql-dev \
        libpcap-dev \
        libxml2-dev \
        libxslt-dev \
        yaml-dev \
        zlib-dev \
        ncurses-dev \
        bison \
        autoconf \
        && rm -rf /var/cache/apk/*

VOLUME [ "/usr/share/metasploit-framework" ]
CMD [ "/usr/local/bin/start.sh" ]
