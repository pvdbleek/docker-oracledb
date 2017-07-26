## Patches applied to Oracle's scripts

First of all, thank you Oracle for still using so much shell scripting. That makes it a lot easier to troubleshoot ;-)

Second, I'm in no way and Oracle DB expert, so my hacks might come accross as brutal to a true expert ;-)
I'm very open to suggestions to improve this.

Here's a brief description of patches and why I chose to patch the scripts:

### setupDB.sh.patch

Persisting ```/u01``` through ```/u04``` was easy, just mount them from docker volumes.
But there are a few other files that live in places like ```/etc``` and ```/home``` that needed to be persisted as well.
I chose to save them to ```/u01``` after configuration so that we can restore them if a new container gets deployed.

### dockerInit.sh.patch

This is the entrypoint to the container. It checks if $ORACLE_HOME already exists and starts the existing database if it's already there.
This patch copies the persisted files from ```/u01``` to their original locations right before the database gets started.

### configDBora.sh.patch

I had an issue that everything came up correctly on my Mac running Docker-for-Mac, but when deployed to my Ubuntu-based swarm, the database would not register itself to the listener.
I *think* that might have to do with a difference in kernel-ipc settings, so to make sure it's absolutely portable between environments I chose to set the ```local_listener``` to TCP on ```localhost``` as the listener is always running in the same container.


### startupDB.sh.patch

Because of my change to ```local_listener``` I had to change the startup order of the database and the listener, as the database would not register itself correctly if the listener was not started yet.