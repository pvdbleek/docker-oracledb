## Deploying a full Oracle stack demo

### Build and push the required images
Build the image for the Oracle WebLogic server including the demo app as described [here](https://github.com/pvdbleek/ddc-weblogic-demo/blob/master/README.md).

Build the image for the Oracle Database server as described [here](https://github.com/pvdbleek/docker-oracledb/blob/master/README.md).

Push both images to a registry of your choice.

Or you can use my pre-built images: ```pvdbleek/wls-app``` and ```pvdbleek/oracledb``` on Hub.

### Pre-req's 

Make sure you create the following before you deploy:

Secret that contains the password to the database:
````
$ echo "Mypass123" | docker secret create oracledb_passwd -
````

Create all of the volumes. We use external ones so we can persist the database's config and data:

````
$ docker volume create oracledb_u01
$ docker volume create oracledb_u02
$ docker volume create oracledb_u03
$ docker volume create oracledb_u04
````
Create a network which is attachable to bot WebLogic and the Database.
(We need to to this because we can't just yet use compose to deploy the entire stack)

````
$ docker network create --attachable -d overlay oranet
````

### Deploy the database

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
      --network oranet \
      --constraint node.hostname==engine4.pvdbleek.dtcntr.net \
      pvdbleek/oracledb
````
Please note the tmpfs filesystem to provide shm. Services do not support ```--shm``` so we have to workaround with ```tmpfs```.
However, compose does not yet support ```tmpfs``` when deploying with ```docker stack```.
That's why you cannot deploy the entire stack with a compose file just yet :-(

If your volumes are new, it will take the DB around 10-15 minutes to create the database. 

P.S. When you have your volumes on shared storage, you can drop the constraint.

### Deploy the weblogic services

Deploy using the following stack file: [https://github.com/pvdbleek/docker-oracledb/blob/master/docker-compose.yml](https://github.com/pvdbleek/docker-oracledb/blob/master/docker-compose.yml)

````
$ docker stack deploy -c docker-compose.yml ora_stack
````

Give Weblogic some time to start. The logs for both services should state ```the server is RUNNING```

The ```wlsadmin``` service will be the first to come online. The ```managedserver``` will follow later when it has been able to register with the ```wlsadmin``` service.
You can scale up the ```managedserver``` service if you want to demonstrate registering new managed servers to the Admin Server.

### Test if all works well

Connect to the Database Express Enterprise Manager:
```https://<swarm_url>:5500/em```

User: SYS / Password: the one that you put in the secret

Connect to the WebLogic management console:
```http://<swarm_url>:7001/console```

User: weblogic / Password: welcome1 (or the one you used while building the image)

Connect to the application on the admin server:
```http://<swarm_url>:7001/docker```

Connect to the application on the managed servers:
```http://<swarm_url>:7002/docker```




