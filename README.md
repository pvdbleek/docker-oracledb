## Deploying a demo Oracle 12c DB container on a docker swarm

Oracle has published a certified docker image for their database on the Docker store:
<https://store.docker.com/images/oracle-database-enterprise-edition>

However, this image is designed to run in a single docker container and does not persist any data or configuration, which means it creates a new database everytime you deploy it in a new container.

I wanted to demonstrate how you can make it run as a docker swarm service with persisted data and configuration.

Unfortunately, that seemed impossible without some hacking of the image, so here goes:

### Building your own image with the official one as a base

First, clone this git repo:

````
$ git clone https://github.com/pvdbleek/docker-oracledb
````

Second, build and push it:

````
$ docker build -t pvdbleek/oracledb .
$ docker push pvdbleek/oracledb
````
### Deploying the image to your swarm

We don't want the password to be stored in plain text somewhere, so let's put it in a docker secret:

````
$ echo "Mypass123" | docker secret create oracledb_passwd -
```` 

Now, on the node that you want to run the database on, create the following named volumes:

(P.S. If you have shared storage, you might want to create the volume there so your db can move around on your worker nodes)

(Note: Your worker will need some serious memory to run this. I recommend at least 16Gb of RAM. Storage will take at least 20Gb of disk space.)

````
$ docker volume create oracledb_u01
$ docker volume create oracledb_u02
$ docker volume create oracledb_u03
$ docker volume create oracledb_u04
````
Now, we can deploy our database as a swarm service:

````
$ docker service create --name oracledb \
      -p 1521:1521 -p 5500:5500 \
      --hostname oracledb \
      --mount type=volume,source=oracledb_u01,destination=/u01 \
      --mount type=volume,source=oracledb_u02,destination=/u02 \
      --mount type=volume,source=oracledb_u03,destination=/u03 \
      --mount type=volume,source=oracledb_u04,destination=/u04 \
      --mount type=tmpfs,dst=/dev/shm,tmpfs-size=4g \
      --secret oracledb_passwd \
      -e DB_PASSWD='$(cat /run/secrets/oracledb_passwd)' \
      --constraint node.hostname==engine4.pvdbleek.dtcntr.net \
      pvdbleek/oracledb
````
P.S. If you have your named volumes on shared storage, you can drop the constraint. 

The first time the container starts, it will create a database for you. This process can take a while (up to 15 mins).

Whenever the task gets rescheduled or restarted, it will start up with the persisted data/configuration. This takes a lot less time (around 1 min).

You can connect to the Express Enterprise Manager console by pointing your browser to:
```https://<swarm_url>:5500/em```

Log in with username SYS and your password you set in the secret.

Thanks to [@dglib](https://github.com/dglib) for figuring out how to replace /dev/shm with a tmpfs filesystem.
