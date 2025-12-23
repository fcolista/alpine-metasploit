# alpine-metasploit

This Docker image allow to run the latest metasploit on Alpine Linux. 

This image can work with or without database support, but having a DB is highly reccomended.

alpine-metasploit works out-of-the-box with official Postgresql docker image.

You can start the alpine-metasploit with PostgreSQL support with the commands:

```
docker network create msf
docker container run -d --name postgres --network msf -e POSTGRES_PASSWORD=postgres -e POSTGRES_USER=postgres postgres:16.1-alpine3.19
docker container run -it --name metasploit --network msf fcolista/alpine-metasploit:alpine-3.23
```

Lightweight and secure Docker image to run Metasploit Framework on Alpine Linux 3.23 with optional PostgreSQL support.

Key features:

Multi-stage build (~400MB compressed)

Non-root msf user (UID 1000)

Ruby + Bundler pinned (2.5.17)

Shallow clone of official Rapid7 repo

Separate data persistence (workspaces, DB)

POSIX-compliant and configurable start.sh

```
# Clone and save files
git clone https://github.com/fcolista/alpine-metasploit
cd alpine-metasploit
docker compose up -d --build

# Check DB status
docker compose exec msf msfconsole -q -x "db_status; exit"

# Access console
docker compose exec msf msfconsole
```

```
# Create network
docker network create msfnet

# PostgreSQL
docker run -d \
  --name msf-postgres \
  --network msfnet \
  -e POSTGRES_PASSWORD=msf \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_DB=msf \
  -v $(pwd)/pgdata:/var/lib/postgresql/data \
  postgres:16-alpine

# Metasploit (wait for PostgreSQL)
docker run -it \
  --name msf \
  --network msfnet \
  -e MSF_DATABASE_HOST=msf-postgres \
  -e MSF_USERNAME=msf \
  -e MSF_PASSWORD=msf \
  -v $(pwd)/msfdata:/msfdata \
  fcolista/alpine-metasploit:3.23
```

| Variable          | Default  | Description               |
| ----------------- | -------- | ------------------------- |
| MSF_DATABASE_HOST | postgres | PostgreSQL host           |
| MSF_USERNAME      | msf      | DB username               |
| MSF_PASSWORD      | msf      | DB password               |
| MSF_DATABASE      | msf      | Database name             |
| MSF_UPDATE        | true     | Run msfupdate on startup  |
| MSF_ARGS          | ``       | Extra args for msfconsole |

No DB: docker run ... -e MSF_DATABASE_HOST="" → starts msfconsole -n

📁 Data persistence
./pgdata/ → PostgreSQL database

./msfdata/ → ~/.msf4/ (workspaces, loot, exploits)

/pgpass → temporary credentials (tmpfs)

🛠️ Useful commands

```
# Logs
docker compose logs -f msf

# Interactive shell
docker compose exec msf sh

# Update Metasploit
docker compose exec msf msfupdate

# DB status
docker compose exec msf msfconsole -q -x "db_status; exit"

# Clean and rebuild
docker compose down -v && docker compose up -d --build
```

🏗️ Custom build


```
git clone https://github.com/fcolista/alpine-metasploit
cd alpine-metasploit
docker build -t my-msf:local .
```

Available tags: fcolista/alpine-metasploit:3.23, :latest


🔒 Security
Runs as msf user (non-root)

Multi-stage build (no dev packages in runtime)

Data volume separate from code

PostgreSQL with healthcheck

⚠️ Use only in isolated environments for authorized penetration testing.

📈 Resources
~450MB compressed image

~1.2GB uncompressed

RAM: 512MB minimum, 2GB recommended

CPU: 1 core minimum

Enjoy! 👨‍💻

Francesco Colista francesco.colista@gmail.com

GitHub | Docker Hub ​

