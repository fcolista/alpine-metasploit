FROM alpine:3.3
MAINTAINER Francesco Colista <fcolista@alpinelinux.org>
COPY ./start.sh /usr/local/bin/start.sh
ENV PATH=$PATH:/usr/share/metasploit-framework
RUN chmod +x /usr/local/bin/start.sh && \
    echo "http://nl.alpinelinux.org/alpine/v3.3/community" >> /etc/apk/repositories && \
    echo "http://nl.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk update && \
	apk add \
	alpine-sdk \
	ruby-dev \
	libffi-dev\
        openssl-dev \
	readline-dev \
	sqlite-dev \
        autoconf \
	bison \
	libxml2-dev \
	postgresql-dev \
        libpcap-dev \
	yaml-dev \
	subversion \
	git \
	sqlite \
	zlib-dev \
	ruby-webrobots \
        ruby-bundler \
	ruby-io-console \
	ruby-nokogiri \
        ruby-activesupport4.2 \
	ruby-activerecord4.2 \
	ruby-bigdecimal \
	ruby-yard \
	ruby-rack \
	ruby-rack-test \
	ruby-minitest \
	ruby-multi_json \
	ruby-erubis \
	ruby-mime-types \
	ruby-tzinfo \
	ruby-builder \
	ruby-erubis \
	ruby-rack-cache \
	ruby-rack-openid \
	ruby-rack-ssl \
	ruby-rack14 \
	ruby-rack-protection \
	ruby-actionpack-action_caching4.2 \
	ruby-actionpack4.2 \
	ruby-actionpack-xml_parser4.2 \
	ruby-mime-types \
	ruby-mail \
	ruby-actionmailer4.2 \
	ruby-activemodel4.2 \
	ruby-arel \
	ruby-activerecord4.2 \
	ruby-diff-lcs \
	ruby-coderay \
	ruby-thor \
	ruby-railties4.2 \
	ruby-hike \
	ruby-tilt \
	ruby-sprockets-rails4.2 \
	ruby-sprockets \
	ruby-rails-dom-testing4.2 \
	ruby-rails-html-sanitizer \
	ruby-rails-deprecated_sanitizer4.2 \
	ruby-json \
	ruby-pg \
	ruby-redcarpet \
	ruby-pry \
	nmap \
        ncurses \
	ncurses-dev && \
        rm -rf /var/cache/apk/*

RUN cd /usr/share && \
    git clone https://github.com/rapid7/metasploit-framework.git && \
    cd /usr/share/metasploit-framework && \
    bundle install

VOLUME [ "/usr/share/metasploit-framework" ]
CMD [ "/usr/local/bin/start.sh" ] 
