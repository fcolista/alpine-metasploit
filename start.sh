#!/bin/sh

cd /usr/share/metasploit-framework
git config --global user.name "msf"
git config --global user.email "msf@localhost"
/usr/share/metasploit-framework/msfupdate

MSFUSER=${MSFUSER:-postgres}
MSFPASS=${MSFPASS:-postgres}
DB_PORT_5432_TCP_ADDR=postgres

echo "${DB_PORT_5432_TCP_ADDR}:5432:postgres:${MSFUSER}:${MSFPASS}" > /root/.pgpass && chmod 0600 /root/.pgpass

if ping -c 1 -W 1 "postgres" &>/dev/null; then
	if ! [ $(psql -h $DB_PORT_5432_TCP_ADDR -p 5432 -U postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='$MSFUSER'") == "1" ]; then
		psql -h $DB_PORT_5432_TCP_ADDR -p 5432 -U postgres -c "create role $MSFUSER login password '$MSFPASS'"
	fi
	if ! [ $(psql -h $DB_PORT_5432_TCP_ADDR -p 5432 -U postgres -lqtA | grep "^msf|" | wc -l) == "1" ]; then
		psql -h $DB_PORT_5432_TCP_ADDR -p 5432 -U postgres -c "CREATE DATABASE msf OWNER $MSFUSER;"
	fi

sh -c "echo 'production:
  adapter: postgresql
  database: msf
  username: $MSFUSER
  password: $MSFPASS
  host: $DB_PORT_5432_TCP_ADDR
  port: 5432
  pool: 75
  timeout: 5' > /usr/share/metasploit-framework/config/database.yml"
	/usr/share/metasploit-framework/msfconsole
else
	/usr/share/metasploit-framework/msfconsole -n
fi
