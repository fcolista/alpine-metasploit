#!/bin/sh
set -euo pipefail

cd /usr/share/metasploit-framework

# Config vars
MSF_DATABASE_HOST="${MSF_DATABASE_HOST:-postgres}"
MSF_DATABASE_PORT="${MSF_DATABASE_PORT:-5432}"
MSF_DATABASE="${MSF_DATABASE:-msf}"
MSF_USERNAME="${MSF_USERNAME:-msf}"
MSF_PASSWORD="${MSF_PASSWORD:-msf}"
MSF_POOL="${MSF_POOL:-75}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-msf}"

# Git config
git config --global user.name "msf" || true
git config --global user.email "msf@localhost" || true

# Update opzionale
if [ "${MSF_UPDATE:-true}" = "true" ]; then
    msfupdate || echo "msfupdate failed, continuing..."
fi

# Crea /tmp/.msf
export HOME="/tmp/.msf"
mkdir -p "$HOME" "$HOME/.msf4"
export MSF_HOME="$HOME"

# Test PostgreSQL
if command -v nc >/dev/null 2>&1 && nc -z -w 3 "$MSF_DATABASE_HOST" "$MSF_DATABASE_PORT" 2>/dev/null; then
    echo "✅ PostgreSQL reachable at $MSF_DATABASE_HOST:$MSF_DATABASE_PORT"
    
    # .pgpass per MSF user
    PGPASSFILE="$HOME/.pgpass"
    printf '%s:%s:%s:%s:%s\n' \
        "$MSF_DATABASE_HOST" "$MSF_DATABASE_PORT" "$MSF_DATABASE" \
        "$MSF_USERNAME" "$MSF_PASSWORD" > "$PGPASSFILE"
    chmod 0600 "$PGPASSFILE"
    export PGPASSFILE

    # Crea DB user/database
    if ! PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$MSF_DATABASE_HOST" -p "$MSF_DATABASE_PORT" -U postgres \
        -tAc "SELECT 1 FROM pg_roles WHERE rolname='$MSF_USERNAME'" | grep -q 1; then
        PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$MSF_DATABASE_HOST" -p "$MSF_DATABASE_PORT" -U postgres \
            -c "CREATE ROLE \"$MSF_USERNAME\" LOGIN PASSWORD '$MSF_PASSWORD';"
        echo "✅ Created DB user $MSF_USERNAME"
    fi

    if ! PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$MSF_DATABASE_HOST" -p "$MSF_DATABASE_PORT" -U postgres \
        -tAc "SELECT 1 FROM pg_database WHERE datname='$MSF_DATABASE'" | grep -q 1; then
        PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$MSF_DATABASE_HOST" -p "$MSF_DATABASE_PORT" -U postgres \
            -c "CREATE DATABASE \"$MSF_DATABASE\" OWNER \"$MSF_USERNAME\";"
        echo "✅ Created database $MSF_DATABASE"
    fi

    PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$MSF_DATABASE_HOST" -p "$MSF_DATABASE_PORT" -U postgres <<EOF
ALTER DATABASE "$MSF_DATABASE" OWNER TO "$MSF_USERNAME";
GRANT ALL PRIVILEGES ON DATABASE "$MSF_DATABASE" TO "$MSF_USERNAME";
\c $MSF_DATABASE
GRANT USAGE, CREATE ON SCHEMA public TO "$MSF_USERNAME";
ALTER SCHEMA public OWNER TO "$MSF_USERNAME";
EOF

    # ✅ INIZIALIZZA DATABASE METASPLOIT
    echo "🔄 Initializing Metasploit database..."
    msfdb init || echo "Database already initialized or minor errors"
    echo "✅ Metasploit database ready"

    # database.yml
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

exec msfconsole ${MSF_ARGS:-}

