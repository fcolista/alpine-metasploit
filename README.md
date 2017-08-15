# alpine-metasploit

This Docker image allow to run the latest metasploit on Alpine Linux. 

This image can work with or without database support, but having a DB is highly reccomended.

alpine-metasploit works out-of-the-box with official Postgresql docker image.

You can start the alpine-metasploit with PostgreSQL support with the commands:

```
docker run -d --name postgres postgres && docker start postgres
docker run -it --link postgres:db fcolista/alpine-metasploit
```
# Note:

If you are running with a grsec kernel, you should disable those features:
```
chroot_deny_chmod
chroot_deny_mknod
```
On an Alpine host, you can do it by decommenting from ```/etc/conf.d/docker```:

```
disable_grsec="chroot_deny_chmod chroot_deny_mknod"
```
and then restart docker:
```
rc-service docker restart
```

Enjoy, Francesco
