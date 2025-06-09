# alpine-metasploit

This Docker image allow to run the latest metasploit on Alpine Linux. 

This image can work with or without database support, but having a DB is highly reccomended.

alpine-metasploit works out-of-the-box with official Postgresql docker image.

You can start the alpine-metasploit with PostgreSQL support with the commands:

```
docker network create msf
docker container run -d --name postgres --network msf -e POSTGRES_PASSWORD=postgres -e POSTGRES_USER=postgres postgres:16.1-alpine3.19
docker container run -it --name metasploit --network msf fcolista/alpine-metasploit:alpine-3.22
```

Enjoy, Francesco
