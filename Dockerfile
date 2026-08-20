# ============ STAGE 1: Builder ============
FROM alpine:3.24.1 AS builder

ARG BUNDLER_VERSION=4.0.19
ARG ALPINE_VER=3.24

RUN echo "http://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VER}/main" >> /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VER}/community" >> /etc/apk/repositories && \
    apk add --no-cache \
        ruby ruby-dev ruby-ffi \
        build-base \
        libffi-dev openssl-dev readline-dev sqlite-dev postgresql-dev \
        libpcap-dev libxml2-dev libxslt-dev yaml-dev zlib-dev ncurses-dev \
        git

RUN gem install bundler -v "${BUNDLER_VERSION}" --no-document

WORKDIR /usr/share
RUN git clone --depth 1 --branch master https://github.com/rapid7/metasploit-framework.git
WORKDIR /usr/share/metasploit-framework

RUN sed -i 's/"stringio", "3.1.1"/"stringio"/' Gemfile || true && \
    bundle config set --local without 'development test' && \
    bundle config set --local path 'vendor/bundle' && \
    bundle install --jobs=4 && \
    bundle clean --force && \
    rm -rf vendor/bundle/ruby/*/cache/*.gem && \
    find vendor/bundle -name "*.md" -type f -delete 2>/dev/null || true

# ============ STAGE 2: Runtime ============
FROM alpine:3.24.1

ARG BUNDLER_VERSION=4.0.19
ARG ALPINE_VER=3.24

RUN echo "http://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VER}/main" >> /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VER}/community" >> /etc/apk/repositories && \
    apk add --no-cache \
        ruby ruby-ffi ruby-bigdecimal ruby-webrick \
        sqlite nmap libxslt libpcap postgresql-client ncurses git \
        libffi libxml2 openssl readline yaml zlib

RUN rm -f /usr/bin/bundle /usr/bin/bundler && \
    gem install bundler -v "${BUNDLER_VERSION}" --no-document && \
    # Assicurati che bundle sia disponibile
    ln -sf /usr/local/bin/bundle /usr/bin/bundle || true

RUN addgroup -g 1000 -S msf && \
    adduser -S -D -H -u 1000 -h /usr/share/metasploit-framework -s /bin/sh -G msf msf

WORKDIR /usr/share/metasploit-framework
COPY --from=builder --chown=msf:msf /usr/share/metasploit-framework .

RUN mkdir -p .bundle && \
    echo '---' > .bundle/config && \
    echo 'BUNDLE_PATH: "vendor/bundle"' >> .bundle/config && \
    echo 'BUNDLE_WITHOUT: "development test"' >> .bundle/config && \
    chown -R msf:msf .bundle

ENV PATH="/usr/share/metasploit-framework/vendor/bundle/bin:/usr/local/bin:/usr/bin:$PATH" \
    BUNDLE_PATH="/usr/share/metasploit-framework/vendor/bundle" \
    BUNDLE_APP_CONFIG="/usr/share/metasploit-framework/.bundle" \
    BUNDLE_WITHOUT="development test" \
    GEM_HOME="/usr/share/metasploit-framework/vendor/bundle" \
    GEM_PATH="/usr/share/metasploit-framework/vendor/bundle" \
    BUNDLE_SILENCE_ROOT_WARNING=1 \
    BUNDLER_VERSION="${BUNDLER_VERSION}" \
    MSF_DATABASE_HOST="postgres" \
    MSF_DATABASE_PORT="5432" \
    MSF_DATABASE="msf" \
    MSF_USERNAME="msf" \
    MSF_PASSWORD="msf" \
    MSF_POOL="75"

COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh && \
    chown msf:msf /usr/local/bin/start.sh

USER msf
EXPOSE 55552 55553
ENTRYPOINT ["/usr/local/bin/start.sh"]
