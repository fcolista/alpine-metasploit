#!/bin/sh

/usr/share/metasploit-framework/msfupdate

MSFUSER=${MSFUSER:-postgres}
MSFPASS=${MSFPASS:-postgres}

if ! [ -z "$DB_PORT_5432_TCP_ADDR" ]; then
	# Check if user exists
	if ! [ $(psql -h $DB_PORT_5432_TCP_ADDR -p 5432 -U postgres postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='$MSFUSER'") == "1" ]; then
		psql -h $DB_PORT_5432_TCP_ADDR -p 5432 -U postgres postgres -c "create role $MSFUSER login password '$MSFPASS'"
	fi
	if ! [ $(psql -h $DB_PORT_5432_TCP_ADDR -p 5432 -U postgres postgres -lqtA | grep "^msf|" | wc -l) == "1" ]; then
		psql -h $DB_PORT_5432_TCP_ADDR -p 5432 -U postgres postgres -c "CREATE DATABASE msf OWNER $MSFUSER;"
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
else
	echo "USAGE:"
	echo "	1. Setup a database:"
	echo "	   docker run -d --name=postgres postgres"
	echo "	2. Link containers:"
	echo "	   docker run -it --link postgres:db fcolista/alpine-metasploit"
	echo ""
	echo " I'm going to run metasploit without DB connection..."
	/usr/share/metasploit-framework/msfconsole -n
fi

/usr/share/metasploit-framework/msfconsole
