# postgres-db-elastos-blockchains

Array of files with instructions to build backend in this README.md.

# To tackle a full Kubernetes installation, ideally you would need a 32 GB RAM; 250 GB SSD; + HDD: PC (x86_64). eg an Extreme Gaming Computer.

We base initial development such as this offline.

You need to develop on docker. ITCSA uses Ubuntu 20.04.

You will not need an Extreme Gaming level of computer for Docker based work without Kubernetes.

See our website at https://www.itcsolutions.com.au/kubernetes-yaml-file-example/ for an older but more visual idea.

Get Docker for Ubuntu: https://docs.docker.com/engine/install/ubuntu/

Remember to `sudo usermod -aG docker $USER && newgrp docker` after install is complete.

The docker-based development on this project is adaptable from the code in:

https://github.com/cyber-republic/elastos-smartweb-service

# The database schemas for ITCSA's project are private and available only under certain conditions.

Development is easiest in Docker as opposed to Kubernetes.

Nevertheless, if you wish to go on to build a full set of nodes with High Availability enabled on Kubernetes, we use Multipass/ Microk8s, as follows.

# Multipass/Micok8s uses the Docker Container runtime.

`sudo snap install multipass`

`multipass launch --name master-node --mem 3G --disk 15G`

`multipass launch --name database-node --mem 4G --disk 50G`

`multipass launch --name blockchains-node --mem 3G --disk 15G`

`multipass launch --name truffle-node --mem 4G --disk 15G`

Open 4 new terminal tabs.

In first:

`multipass shell master-node`

In second:

`multipass shell database-node`

In third:

`multipass shell blockchains-node` 

In fourth:

`multipass shell truffle-node`

In first (within master-node):

`sudo snap install microk8s --classic --channel=1.19`

.. wait .. when installed:

`sudo iptables -P FORWARD ACCEPT`

`sudo usermod -a -G microk8s $USER`

`sudo chown -f -R $USER ~/.kube`

`sudo passwd ubuntu` (enter new password and repeat)

`su - $USER`

`microk8s enable ambassador dashboard dns ha-cluster metrics-server registry storage`

Repeat above 7 commands in each of database-node, blockchains-node, truffle-node.

Check state of microk8s in each node:

`microk8s status --wait-ready` x 4

if all is well continue below. If any node is no longer running microk8s, sudo snap remove microk8s then reinstall as above.

When every node is running microk8s:

On master-node

`microk8s add-node`  ... and copy the join command to the database node.

When the database-node has joined, repeat for blockchains-node.

Go ahead and add the truffle-node to the cluster.

Recheck microk8s status on every node.

{`sudo snap remove microk8s`, reinstall, enable add-ons (see above) and join again, in case of microk8s not running.}

Next we need to label the nodes:

`microk8s kubectl label nodes master-node nodetype=master-node`

`microk8s kubectl label nodes database-node nodetype=database-node`, etc

Now in each node we require a shared directory to mount your host repo directory into.

So:

in each node `mkdir /home/ubuntu/shared`

FROM HOST TERMINAL: clone the repo:

`git clone https://github.com/john-itcsolutions/postgres-db-elastos-blockchains.git`

# As this is forked from Arianitu's github site, the head README.md file applies to building the database only. The README.md for postgres-db-elastos-blockchains had to be placed inside the config folder.

Then:

`multipass mount /your/repo/host/path/postgres-db-elastos-blockchains  master-node:/home/ubuntu/shared`

`multipass mount /your/repo/host/path/postgres-db-elastos-blockchains database-node:/home/ubuntu/shared`

`multipass mount /your/repo/host/path/postgres-db-elastos-blockchains blockchains-node:/home/ubuntu/shared`

`multipass mount /your/repo/host/path/postgres-db-elastos-blockchains truffle-node:/home/ubuntu/shared`

 IN HOST TERMINAL:
 
 Now we pull the images we need:

 `docker pull redis:5.0.4`

 `docker pull postgres:10.14`
 
  `docker pull postgrest/postgrest:latest`
 
 .. from the Elastos Develap Binaries, we have examined the output of a Docker subsystem running the following Blockchains, and managed to reconstruct the system as a Kubernetes Deployment.

 `docker pull cyberrepublic/elastos-mainchain-node:v0.3.7`
 
 `docker pull cyberrepublic/elastos-sidechain-did-node:v0.1.2`
 
 `docker pull cyberrepublic/elastos-sidechain-token-node:v0.1.2`
 
 `docker pull cyberrepublic/elastos-sidechain-eth-node:latest`
 
 Issue `multipass list` from host and note Ip Address of the master-node.
 
 `sudo nano /etc/docker/daemon.json`

 You need to have something like:
 
`{`

`  insecure-registries : [10.184.36.93:32000,`

`                           ]`

`}`

where the 2 Ip Addresses must match your master-node address. (Use `multipass list` on the host)

Then:

`sudo systemctl daemon reload`

`sudo systemctl restart docker`

`docker tag redis:5.0.4 10.184.36.93:32000/redis:5.0.4`

`docker tag postgres:10.14 10.184.36.93:32000/postgres:10.14`

`docker tag postgrest/postgrest:latest 10.184.36.93:32000/postgrest/postgrest:registry`

`docker tag cyberrepublic/elastos-mainchain-node:v0.3.7 10.184.36.93:32000/cyberrepublic/elastos-mainchain-node:v0.3.7`

`docker tag cyberrepublic/elastos-sidechain-did-node:v0.1.2 10.184.36.93:32000/cyberrepublic/elastos-sidechain-did-node:v0.1.2`

`docker tag cyberrepublic/elastos-sidechain-token-node:v0.1.2 10.184.36.93:32000/cyberrepublic/elastos-sidechain-token-node:v0.1.2`

`docker tag cyberrepublic/elastos-sidechain-eth-node:latest 10.184.36.93:32000/cyberrepublic/elastos-sidechain-eth-node:registry`

`docker push 10.184.36.93:32000/redis:5.0.4`

`docker push 10.184.36.93:32000/postgres:10.14`

`docker push 10.184.36.93:32000/postgrest/postgrest:registry`

`docker push 10.184.36.93:32000/cyberrepublic/elastos-mainchain-node:v0.3.7`

`docker push 10.184.36.93:32000/cyberrepublic/elastos-sidechain-did-node:v0.1.2`

`docker push 10.184.36.93:32000/cyberrepublic/elastos-sidechain-token-node:v0.1.2`

`docker push 10.184.36.93:32000/cyberrepublic/elastos-sidechain-eth-node:registry`

(Remember to change the above Ip Addresses to match your own node address for master node!)

Now in database-node:

`cd /home/ubuntu/shared/path/to/postgres-db-elastos-blockchains`

Run `microk8s kubectl apply -f config/secret.yml` and then `cd config && ./create_configmap.sh`    

`cd ../`

Generate further secrets from kustomization file:

`microk8s kubectl apply -k .`

Create places for persistent volumes on database-node and allow access:

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

_________________________________________________

Still in database-node, start master postgres server:

`microk8s kubectl apply -f statefulset-master.yml`

In master-node, check pod:

`watch microk8s kubectl get pods`

If errors or excessive delay get messages with:

`microk8s kubectl describe pods`

 .. fix errors!
 
 In database-node, after master is successfully running and ready, start replica server:

`microk8s kubectl apply -f statefulset-replica.yml`
 
 Check pods in master node. If all is well:
 
 Database-node:
 
`microk8s kubectl apply -f haskell.yml`

check pods ..

`microk8s kubectl apply -f redis-cheirrs.yml`

check pods ..

`microk8s kubectl apply -f redis-cheirrs-oseer.yml`

check pods ..

`microk8s kubectl apply -f redis-a-horse.yml`

check pods ..
 
 ______________________________________________________________________
 
`microk8s kubectl cp create_table_scripts.sql postgres-0:/var/lib/postgresql/data/`

`microk8s kubectl cp insert_rows_scripts.sql postgres-0:/var/lib/postgresql/data/`

`microk8s kubectl cp reset_database.sql postgres-0:/var/lib/postgresql/data/`

# The following 3 commands would be possible only after you are positively identified, gain our trust, and sign an agreement to work with us, in order to obtain these backup files. Or, develop your own!

`microk8s kubectl cp ../cheirrs_backup.sql postgres-0:/var/lib/postgresql/data/`

`microk8s kubectl cp ../cheirrs_oseer_backup.sql postgres-0:/var/lib/postgresql/data/`

`microk8s kubectl cp ../a_horse_backup.sql postgres-0:/var/lib/postgresql/data/`
 
`microk8s kubectl exec -it postgres-0 -- sh`

Inside postgres-0 container on database-node:

`apk add nano`

(To obtain editor. Choose your own if you wish. Note the Postgresql deployment is based on an Alpine Linux image, and is therefore somewhat different to Ubuntu.)

`su postgres`

`createdb general`

`psql general < /var/lib/postgresql/data/cheirrs_backup.sql`

`psql general < /var/lib/postgresql/data/cheirrs_oseer_backup.sql`

`psql general < /var/lib/postgresql/data/a_horse_backup.sql`

Create users in postgres:

`psql general`

`create role cheirrs_user with login password 'passwd';`

`create role cheirrs_admin with superuser login password 'passwd';`                 

`create role cheirrs_oseer_admin with superuser login password 'passwd';`

`create role a_horse_admin with superuser login password 'passwd';`     

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

______________________________________________________

## Blockchains

Now we turn to setting up the Blockchain Deployment, on the blockchains-node:

In the master-node terminal,

`cd shared/path/to/postgres-db-elastos-blockchains `

`microk8s kubectl apply -f elastos-develap.yml`

You can edit secret.yml but then you need to alter the redis-xyz.yml's as the hash for postgres key will change. So you would have to find the hashes in the redis yml files and alter to match newly created key - ie with `microk8s kubectl apply -k .`, and then:

`microk8s kubectl delete deployments redis-cheirrs redis-cheirrs-oseer redis-a-horse`

and restart from above. The deployments may be freely created and deleted at this stage as they are not programmed instances of Redis, more placeholders. Likewise with the Haskell webserver, it is an adaptable element which can readily be destroyed and recreated.

(Track on master-node with `watch microk8s kubectl get pods`)

At this stage you should edit /var/lib/postgresql/data/pgdata/pg_hba.conf to allow access from the elastos blockchains pod, the Haskell webserver, and the 3 redis pods, by obtaining their ip addresses from:

`microk8s kubectl describe pods`,

and editing pg_hba.conf to include these addresses with /24 as the CIDR, and on trust basis.

## Please help! ##

The following is experimental:

In truffle terminal:

`sudo apt-get update`

`sudo apt-get install npm`

`sudo npm install -g truffle solc @truffle/hdwallet-provider`

`truffle init`

`nano truffle-config.js`

By deleting the comment "//"'s in the "development" section in "networks", you need to enable the development network to connect to the Elastos/Eth blockchain. Although the documentation at https://developer.elastos.org/elastos_core_services/guides/ethereum_smart_contracts/deploying_smart_contracts/ gives the Eth rpc port number in the Elastos System as 21636, in Kubernetes that number refers only to the port on the Elastos Ethereum Blockchain Container, and is inaccessible at that number from outside the container.

However if you issue (on a second master-node terminal):

`microk8s kubectl get services`

you will see there is a nodePort number associated with each Elastos port. The nodePort number corresponding to Elastos Port Number 21636 should be inserted in the network config for Truffle. The network_id should be "3", and the host Ip-Address to use is the vm (node) address of the blockchain-node - obtainable from:

`multipass list`, run on the Host computer.

The remaining edits required for truffle-config.js are on the latter webpage.

You should follow that page for a link to the ELA/ETH "faucet" where we are supposed to obtain Test Eth. I found it failed repeatedly and we have zero Test ELA/ETH. :(   ...

We did find that we could successfully connect to the Truffle development network (as paupers) with the above nodePort config. After running

`truffle console --network development`

we were able to obtain an Eth Account Address with:

`web3.eth.personal.newAccount("MY_PASSWORD")`

We then inserted that Account Address into the truffle-config.js file as described on the above Elastos webpage.

At the very least this means we have managed to successfully construct a fully connected Kubernetes backend for the Database and Blockchains (based on Postgresql and the Elastos Develap Binaries) with a Truffle node upon which solidity smart contracts programming would be able to occur against the Blockchains, given we had some Test ELA/ETH. We are able to launch a connected Truffle Development Environment in truffle-node, it's just the ELA/ETH Test Faucet is either not working or holds secrets we have yet to uncover ..
