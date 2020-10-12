# postgres-db-elastos-blockchains

Array of files with instructions to build backend in this README.md.

Ideally you will need a 32 GB RAM; 250 GB SSD; + HDD PC (x32_64). eg an Extreme Gaming Computer.

We base initial development such as this offline.

You need to develop on docker. ITCSA uses Ubuntu 20.04. https://docs.docker.com/engine/install/ubuntu/

Remember to sudo `usermod -aG docker $USER && newgrp docker` after install is complete.

To go on to build a full set of nodes with High Availability enabled on Kubernetes, we use Multipass/ Microk8s.

`sudo snap install multipass --beta --classic`

`multipass launch --name master-node --mem 3G --disk 15G`

`multipass launch --name database-node --mem 8G --disk 50G`

`multipass launch --name ipfs1-node --mem 2G --disk 10G`

`multipass launch --name ipfs2-node --mem 2G --disk 10G`

`multipass launch --name carrier-node --mem 2G --disk 10G`

`multipass launch --name hive-node --mem 3G --disk 15G`

Open 7 new terminal tabs.

In first:

`multipass shell master-node`

In second:

`multipass shell database-node`

In third:

`multipass shell database-node` (yes, that's correct)

In fourth:

`multipass shell ipfs1-node`

In fifth:

`multipass shell ipfs2-node`

In sixth:

`multipass shell hive-node`

In seventh:

`multipass shell carrier-node`

In first (within master-node):

`sudo snap install microk8s --classic --channel=1.19`

.. wait .. when installed:

`sudo iptables -P FORWARD ACCEPT`

`sudo usermod -a -G microk8s $USER`

`sudo chown -f -R $USER ~/.kube`

`sudo passwd ubuntu` (enter new password and repeat)

`su - $USER`

`microk8s enable ambassador dashboard dns ha-cluster metrics-server registry storage`

Repeat above 7 commands in each of database-node, ipfs1-node, ipfs2-node, hive-node and carrier-node.

Check state of microk8s in each node:

`microk8s status` x 6

if all is well continue below. If any node is no longer running microk8s, sudo snap remove microk8s then reinstall as above.

When every node is running microk8s:

On master-node

`microk8s add-node`  ... and copy the join command to the database node.

When the database-node has joined, repeat for ipfs1-node.

The limit of nodes in a sub-cluster is 3, with one master per sub-cluster, 

where any node issuing join command with `microk8s add-node` will be treated as a master node. 

We have 6 nodes so we choose the hive-node as the second master from which we will issue join commands to ipfs2 and carrier. 

Go ahead and add those 2 nodes to the hive-node sub-cluster.

Recheck microk8s status on every node.

{`sudo snap remove microk8s`, reinstall, enable add-ons (see above) and join again, in case of microk8s not running.}

If you cannot get the second sub-cluster to run, it is still quite feasible to run only a single 3 node HA-Cluster. 

Leave out ipfs2 (or ipfs1), Hive and Carrier if necessary. If you want HA, you need 3 nodes running and joined.

Next we need to label the nodes:

`microk8s kubectl label nodes master-node nodetype=master-node`

`microk8s kubectl label nodes database-node nodetype=database-node`, etc

Now in each node we require a shared directory to mount your host repo directory into.

So:

in each node `mkdir /home/ubuntu/shared`

FROM HOST TERMINAL: clone the repo:

`git clone https://github.com/john-itcsolutions/postgres-db-elastos-blockchains.git`

As this is forked from Arianitu's github site, the head README.md file applies to building the database only. The README.md for postgres-db-elastos-blockchains had to be placed inside the config folder.

Then:

`multipass mount /your/repo/host/path/john-itcsolutions/postgres-db-elastos-blockchains  master-node:/home/ubuntu/shared`

`multipass mount /your/repo/host/path/john-itcsolutions/postgres-db-elastos-blockchains database-node:/home/ubuntu/shared`

`multipass mount /your/repo/host/path/john-itcsolutions/postgres-db-elastos-blockchains ipfs1-node:/home/ubuntu/shared`

`multipass mount /your/repo/host/path/john-itcsolutions/postgres-db-elastos-blockchains ipfs2-node:/home/ubuntu/shared`

`multipass mount /your/repo/host/path/john-itcsolutions/postgres-db-elastos-blockchains hive-node:/home/ubuntu/shared`

`multipass mount /your/repo/host/path/john-itcsolutions/postgres-db-elastos-blockchains  carrier-node:/home/ubuntu/shared`

 IN HOST TERMINAL:

`docker login` (You need to be a collaborator as johnitcsolutionscomau/ubuntu_elastos_smartweb-base is a private repo).
 
 Now we pull the images we need:

 `docker pull redis:5.0.4`

 `docker pull postgres:10.14`

 `docker pull postgrest/postgrest`

 `docker pull johnitcsolutionscomau/ubuntu_elastos_smartweb-base` 
 
 Issue `multipass list` from host and note Ip Address of both the master-node and (if following with second sub-cluster) hive-node.
 
 `sudo nano /etc/docker/daemon.json`

 You need to have something like:
 
`{
  insecure-registries : [10.184.36.93:32000,
                           10.184.36.143:32000]
}`

where the 2 Ip Addresses must match your master-node and hive-node addresses.

Then:

`sudo systemctl daemon reload`

`sudo systemctl restart docker`

`docker tag redis:5.0.4 10.184.36.93:32000/redis:5.0.4`

`docker tag postgres:10.14 10.184.36.93:32000/postgres:10.14`

`docker tag postgrest/postgrest:latest 10.184.36.93:32000/postgrest/postgrest:registry`

Note in following, johnitcsolutionscomau/ubuntu_elastos_smartweb-base is a private repo. You will need to be a collaborator to see it.

`docker tag johnitcsolutionscomau/ubuntu_elastos_smartweb-base:latest 10.184.36.93:32000/johnitcsolutionscomau/ubuntu_elastos_smartweb-base:1`

`docker tag johnitcsolutionscomau/ubuntu_elastos_smartweb-base:latest 10.184.36.143:32000/johnitcsolutionscomau/ubuntu_elastos_smartweb-base:1`

`docker push 10.184.36.93:32000/redis:5.0.4`

`docker push 10.184.36.93:32000/postgres:10.14`

`docker push 10.184.36.93:32000/postgrest/postgrest:registry`

`docker push 10.184.36.93:32000/johnitcsolutionscomau/ubuntu_elastos_smartweb-base:1`

docker push 10.184.36.143:32000/johnitcsolutionscomau/ubuntu_elastos_smartweb-base:1`

(Remember to change the above Ip Addresses to match your own node addresses for master and hive nodes!)

Now in database-node:

`cd /home/ubuntu/shared/path/to/postgres-db-elastos-blockchains`

Run `microk8s kubectl apply -f config/secret.yml` and then `cd config && ./create_configmap.sh`    

`cd ../`

`microk8s kubectl apply -k ../kustomize-general`

`sudo mkdir -p /mnt/disk/pgdata`

`sudo mkdir -p /mnt/disk/pgdata-replica2`

`sudo mkdir -p /mnt/disk/postgres-config3`

`sudo mkdir -p /mnt/disk/config-a-horse`

`sudo mkdir -p /mnt/disk/config-cheirrs`

`sudo mkdir -p /mnt/disk/config-cheirrs-oseer`

`sudo mkdir -p /mnt/disk/data-a-horse`

`sudo mkdir -p /mnt/disk/data-cheirrs`

`sudo mkdir -p /mnt/disk/data-cheirrs-oseer`

`sudo chmod 777 /mnt/disk/pgdata`

`sudo chmod 777 /mnt/disk/pgdata-replica2`

`sudo chmod 777 /mnt/disk/postgres-config3`

`sudo chmod 777 /mnt/disk/config-a-horse`

`sudo chmod 777 /mnt/disk/config-cheirrs`

`sudo chmod 777 /mnt/disk/config-cheirrs-oseer`

`sudo chmod 777 /mnt/disk/data-a-horse`

`sudo chmod 777 /mnt/disk/data-cheirrs`

`sudo chmod 777 /mnt/disk/data-cheirrs-oseer`

Still in database-node:

`microk8s kubectl apply -f statefulset-master.yml`

In master-node:

`watch microk8s kubectl get pods`

If errors or excessive delay get messages with:

`microk8s kubectl describe pods`

 .. fix errors!
 
 In database-node:

`microk8s kubectl apply -f statefulset-replica.yml`
 
 Check pods in master node. If all is well:
 
 Database-node:

`microk8s kubectl apply -f redis-cheirrs.yml`

`microk8s kubectl apply -f redis-cheirrs-oseer.yml`

`microk8s kubectl apply -f redis-a-horse.yml`
 
 Database-node:

`microk8s kubectl apply -f haskell.yml`

 (This is the webserver to be used in place of so far unprogrammed Redis Servers).
 
 To obtain external access:
 
 `microk8s kubectl apply -f ingress.yml`
 
`microk8s kubectl cp create_table_scripts.sql postgres-0:/var/lib/postgresql/data/`

`microk8s kubectl cp insert_rows_scripts.sql postgres-0:/var/lib/postgresql/data/`

`microk8s kubectl cp reset_database.sql postgres-0:/var/lib/postgresql/data/`

The following 3 commands will be possible only after you are positively identified, gain our trust, and sign an agreement in order to obtain these backup files.

`microk8s kubectl cp ../cheirrs_backup.sql postgres-0:/var/lib/postgresql/data/`

`microk8s kubectl cp ../cheirrs_oseer_backup.sql postgres-0:/var/lib/postgresql/data/`

`microk8s kubectl cp ../a_horse_backup.sql postgres-0:/var/lib/postgresql/data/`
 
`microk8s kubectl exec -it postgres-0 -- sh`

Inside postgres-0 container on database-node:

`su postgres`

`createdb general`

`psql general < /var/lib/postgresql/data/cheirrs_backup.sql`

`psql general < /var/lib/postgresql/data/cheirrs_oseer_backup.sql`

`psql general < /var/lib/postgresql/data/a_horse_backup.sql`

Create users in postgres:

`psql general`

`create role cheirrs_user with login password 'Buddha10';`

`create role cheirrs_admin with superuser login password 'Buddha10';`                 

`create role cheirrs_oseer_admin with superuser login password 'Buddha10';`

`create role a_horse_admin with superuser login password 'Buddha10';`     

Check Schemas: there should be 'public, 'a_horse'; 'cheirrs'; 'cheirrs_oseer'.

`\dn`

Check off users:

`\du`

`\dt` should reveal no instances (in public schema)

`set search_path to 'cheirrs';`

`\dt` should reveal a full set of 600+ tables in 2 categories: 1) accounting_xyz and 2) uc_uvw (for use_case)

You will see identical table sets at this stage in development, by altering search_path before `\dt`, to examine cheirrs_oseer and a_horse schemas.

In postgres-0 container on database-node:

Exit psql shell:

`\q`

Run Elastos scripts to prepare database public schema for Blockchains interaction;

`psql -h localhost -d general -U gmu -a -q -f create_table_scripts.sql`

`psql -h localhost -d general -U gmu -a -q -f insert_rows_scripts.sql`

Now if you 

`psql general`

then

`\dt` (to reveal tables in default public schema) you should see 3 tables.

Try:

`select * from users;`

You should see the single user's details.



Now switch to the second database-node terminal:

`cd shared/postgres-db-elastos-blockchains `

`microk8s kubectl apply -f elastos-smartweb.yml`

(Track on master-node with `watch microk8s kubectl get pods`)

When node is up and ready, copy id of pod to clipboard from master node (`watch microk8s kubectl get pods`), and insert below:

`microk8s kubectl exec -it elastos-abcd1234-uvw542xy -- bash`

You are now inside the elastos-smartweb container from which we will be running the blockchains on a python-based grpc server.

`cd elastos-smartweb-service`

1. `apt-get install python3-dev`

2. `curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py`

3. `python3 get-pip.py`

4. `pip3 install virtualenv`

5. `'add-apt-repository ppa:ethereum/ethereum`

6. `apt-get update`

7. `apt-get install solc`

8. `virtualenv -p ``which python3`` venv`

NOTE: There should be single backticks around which python3!

9. `source venv/bin/activate`

10. `pip3 install -r requirements.txt`

11. `export PYTHONPATH=$PYTHONPATH:$PWD/grpc_adenine/stubs/`

12. `cp .env.example .env`

13. `apk add nano`

14. `nano .env`

change host to postgres, port to 5432 and database to general.

ctl-O > Enter > ctrl-X to save and exit.

Still in postgres-0 container on database-node in elastos-smartweb-service directory:

The following should start the blockchain connections

`python3 grpc_adenine/server.py`

Now db and blockchains are running and connected.


At this stage we need to discover how to issue requests to blockchain grpc server and haskell webserver.

Please help!


For the remaining nodes (ipfs1, ipfs2, hive, carrier) the procedure involves running the yml for the node (eg ipfs1.yml) from the master node of the cluster. If you have a second 3-node sub-cluster with acting master as hive-node, and High Availability enabled, you can also run the yml's from their own nodes. The ipfs1-node is assumed to be joined to master-node sub-cluster. The remaining 3 nodes are assumed to be joined on hive-node as master. Running `microk8s kubectl apply -f shared/path to/postgres-db-elastos-blockchains/hive.yml` is a start. Follow with the rest.

Now the elastos/ubuntu containers are running with sleep time of 10,000 seconds during which you can complete server setups and start ipfs, hive and carrier nodes (after compiling on the nodes).

Hive is the Elastos file storage system and relies on IPFS nodes to function. You require at least 2 ipfs nodes to obtain a private network which is consensus-capable.

For ipfs compilation and installation please follow:

https://github.com/ahester57/ipfs-private-swarm

NOTE: An easy way to install go is at https://gist.github.com/d2s/6503f815431d1587c28bc37bfd715dbf

For hive compilation and installation please follow:

https://github.com/elastos/Elastos.NET.Hive.Native.SDK#1-install-pre-requirements

The carrier network is the secure communications system developed by Rong Chen and used in his Elastos system. This is a simple message exchange node but the functions provided by carrier actually enable internet communication with full programmatic ability.

For carrier compilation and installation please follow:

https://github.com/elastos/Elastos.NET.Carrier.Native.SDK#2-install-pre-requirements
