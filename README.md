# alpine-metasploit

## alpine-metasploit

This Docker image allow to run the latest metasploit on Alpine Linux. 

This image can work with or without database support, but having a DB is highly reccomended.

alpine-metasploit works out-of-the-box with official Postgresql docker image.

You can start the alpine-metasploit with PostgreSQL support with the commands:

```
docker run -d --name postgres postgres && docker start postgres
docker run -it --link postgres:db fcolista/alpine-metasploit
```

Enjoy, Francesco
