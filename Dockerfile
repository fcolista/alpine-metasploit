FROM alpine:3.23.2

LABEL org.opencontainers.image.authors="francesco.colista@gmail.com" \
      org.opencontainers.image.source="https://github.com/fcolista/alpine-metasploit"

ARG BUNDLER_VERSION=2.5.17
ARG ALPINE_VER=3.23

ENV PATH="/usr/share/metasploit-framework:$PATH" \
    BUNDLER_VERSION="${BUNDLER_VERSION}" \
    MSF_DATABASE_HOST="postgres" \
    MSF_DATABASE_PORT="5432" \
    MSF_DATABASE="msf" \
    MSF_USERNAME="msf" \
    MSF_PASSWORD="msf" \
    MSF_POOL="75"

# Add community repo
RUN echo "http://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VER}/community" >> /etc/apk/repositories

# Builder stage packages
RUN apk add --no-cache --virtual .build-deps \
    build-base \
    ruby-dev \
    libffi-dev \
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
    git \
    subversion

# Runtime packages
RUN apk add --no-cache \
    ruby \
    ruby-bigdecimal \
    ruby-bundler \
    ruby-webrick \
    sqlite \
    nmap \
    libxslt \
    postgresql-client \
    postgresql \
    ncurses \
    libpcap \
    git

# Install specific bundler version
RUN gem install bundler -v "${BUNDLER_VERSION}" --no-document

# Clone and install Metasploit (shallow clone for speed)
WORKDIR /usr/share
RUN git clone --depth 1 --branch master https://github.com/rapid7/metasploit-framework.git
WORKDIR /usr/share/metasploit-framework

# Bundle install with production flags
RUN sed -i 's/"stringio", "3.1.1"/"stringio"/' Gemfile || true && \
    bundle config set without 'development test' && \
    bundle install

# Create msf user
RUN addgroup -g 1000 -S msf && \
    adduser -S -D -H -u 1000 -h /usr/share/metasploit-framework -s /bin/sh -G msf msf && \
    chown -R msf:msf /usr/share/metasploit-framework

COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

WORKDIR /usr/share/metasploit-framework
USER msf

EXPOSE 55552 55553
ENTRYPOINT ["/usr/local/bin/start.sh"]
