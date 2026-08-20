#!/bin/sh
set -e

cd /usr/share/metasploit-framework

MSF_DATABASE_HOST="${MSF_DATABASE_HOST:-postgres}"
MSF_DATABASE_PORT="${MSF_DATABASE_PORT:-5432}"
MSF_DATABASE="${MSF_DATABASE:-msf}"
MSF_USERNAME="${MSF_USERNAME:-msf}"
MSF_PASSWORD="${MSF_PASSWORD:-msf}"
MSF_POOL="${MSF_POOL:-75}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-msf}"

export BUNDLE_GEMFILE="/usr/share/metasploit-framework/Gemfile"
export BUNDLE_PATH="/usr/share/metasploit-framework/vendor/bundle"
export BUNDLE_APP_CONFIG="/usr/share/metasploit-framework/.bundle"
export BUNDLE_WITHOUT="development test"
export GEM_HOME="/usr/share/metasploit-framework/vendor/bundle"
export GEM_PATH="/usr/share/metasploit-framework/vendor/bundle"

export PATH="/usr/share/metasploit-framework/vendor/bundle/bin:/usr/local/bin:/usr/bin:$PATH"

BUNDLE_CMD=""
if [ -f "/usr/share/metasploit-framework/vendor/bundle/bin/bundle" ]; then
    BUNDLE_CMD="/usr/share/metasploit-framework/vendor/bundle/bin/bundle"
    echo "✅ Using bundle from vendor directory"
elif command -v bundle >/dev/null 2>&1; then
    BUNDLE_CMD="bundle"
    echo "✅ Using bundle from PATH: $(which bundle)"
else
    echo "❌ Bundle not found, installing..."
    gem install bundler -v "${BUNDLER_VERSION:-4.0.19}" --no-document
    BUNDLE_CMD="bundle"
fi

echo "✅ Bundler version: $($BUNDLE_CMD --version 2>/dev/null || echo 'unknown')"

git config --global user.name "msf" 2>/dev/null || true
git config --global user.email "msf@localhost" 2>/dev/null || true

export HOME="/tmp/.msf"
mkdir -p "$HOME" "$HOME/.msf4"
export MSF_HOME="$HOME"

if command -v nc >/dev/null 2>&1 && nc -z -w 5 "$MSF_DATABASE_HOST" "$MSF_DATABASE_PORT" 2>/dev/null; then
    echo "✅ PostgreSQL reachable at $MSF_DATABASE_HOST:$MSF_DATABASE_PORT"

    PGPASSFILE="$HOME/.pgpass"
    printf '%s:%s:%s:%s:%s\n' \
        "$MSF_DATABASE_HOST" "$MSF_DATABASE_PORT" "$MSF_DATABASE" \
        "$MSF_USERNAME" "$MSF_PASSWORD" > "$PGPASSFILE"
    chmod 0600 "$PGPASSFILE"
    export PGPASSFILE

    if ! PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$MSF_DATABASE_HOST" -p "$MSF_DATABASE_PORT" -U postgres \
        -tAc "SELECT 1 FROM pg_roles WHERE rolname='$MSF_USERNAME'" 2>/dev/null | grep -q 1; then
        PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$MSF_DATABASE_HOST" -p "$MSF_DATABASE_PORT" -U postgres \
            -c "CREATE ROLE \"$MSF_USERNAME\" LOGIN PASSWORD '$MSF_PASSWORD';" 2>/dev/null || true
        echo "✅ Created DB user $MSF_USERNAME"
    fi

    if ! PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$MSF_DATABASE_HOST" -p "$MSF_DATABASE_PORT" -U postgres \
        -tAc "SELECT 1 FROM pg_database WHERE datname='$MSF_DATABASE'" 2>/dev/null | grep -q 1; then
        PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$MSF_DATABASE_HOST" -p "$MSF_DATABASE_PORT" -U postgres \
            -c "CREATE DATABASE \"$MSF_DATABASE\" OWNER \"$MSF_USERNAME\";" 2>/dev/null || true
        echo "✅ Created database $MSF_DATABASE"
    fi

    echo "🔄 Setting up database permissions..."
    PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$MSF_DATABASE_HOST" -p "$MSF_DATABASE_PORT" -U postgres <<EOF 2>/dev/null || true
ALTER DATABASE "$MSF_DATABASE" OWNER TO "$MSF_USERNAME";
GRANT ALL PRIVILEGES ON DATABASE "$MSF_DATABASE" TO "$MSF_USERNAME";
\c $MSF_DATABASE
GRANT USAGE, CREATE ON SCHEMA public TO "$MSF_USERNAME";
ALTER SCHEMA public OWNER TO "$MSF_USERNAME";
EOF

    echo "🔄 Initializing Metasploit database..."
    $BUNDLE_CMD exec msfdb init 2>/dev/null || echo "Database already initialized or minor errors"
    echo "✅ Metasploit database ready"

    cat > config/database.yml << EOF
production:
  adapter: postgresql
  database: $MSF_DATABASE
  username: $MSF_USERNAME
  password: $MSF_PASSWORD
  host: $MSF_DATABASE_HOST
  port: $MSF_DATABASE_PORT
  pool: $MSF_POOL
  timeout: 5
EOF
    echo "✅ Database configured"
else
    echo "⚠️ No PostgreSQL, running without DB"
fi

echo "🚀 Starting Metasploit Framework..."
exec $BUNDLE_CMD exec msfconsole ${MSF_ARGS:-}
