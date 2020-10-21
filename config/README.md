# postgres-db-elastos-blockchains

Array of files with instructions to build backend in this README.md.

# To tackle a full Kubernetes installation, ideally you would need a 32 GB RAM; 250 GB SSD; + HDD: PC (x86_64). eg an Extreme Gaming Computer.

We base initial development such as this offline.

You need to develop on docker. ITCSA uses Ubuntu 20.04.

You will not need an Extreme Gaming level of computer for Docker based work without Kubernetes.

See our website at https://www.itcsolutions.com.au/kubernetes-yaml-file-example/ for an older but more visual idea of this project and others.

# Get

Docker for Ubuntu: https://docs.docker.com/engine/install/ubuntu/

Remember to

`sudo usermod -aG docker $USER && newgrp docker` 

after install is complete.

The docker-based development on this project is adaptable from the code in:

https://developer.elastos.org/get_started/setup/env_setup/setup_develap/

and

https://developer.elastos.org/elastos_core_services/guides/ethereum_smart_contracts/

# (The database schemae for ITCSA's project are private and available only under certain conditions.)

Development is easiest in Docker as opposed to Kubernetes.

Nevertheless, if you wish to go on to build a full set of nodes with High Availability enabled on Kubernetes, we use Multipass/ Microk8s, as follows.

# Multipass/Microk8s uses the Docker Container runtime.

`sudo snap install multipass`

`multipass launch --name master-node --mem 3G --disk 15G`

`multipass launch --name database-node --cpus 2 --mem 3G --disk 20G`

`multipass launch --name blockchains-node --mem 3G --disk 20G`

`multipass launch --name truffle-node --mem 3G --disk 10G`

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

(Note: You need to use `micok8s leave` in the terminal of any node you intend to stop, delete and puge with multipass. Also run `microk8s remove-node <node_name>` on the master-node before stopping the target node.)

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
 
 .. by running the Elastos Develap Binaries, we have examined the output of a Docker subsystem running the following Blockchains, and managed to reconstruct the system as a Kubernetes Deployment.

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

where the Ip Address must match your master-node address. (Use `multipass list` on the host)

Then:

`sudo systemctl daemon-reload`

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

Note: "You can edit secret.yml but then you need to alter the redis-xyz.yml's and haskell.yml as the hash for the keys will change. So you would have to find the hashes in those yml files and alter to match newly created keys - from `microk8s kubectl apply -k .`"

Run `microk8s kubectl apply -f config/secret.yml` and then `cd config && ./create_configmap.sh`    

`cd ../`

Generate further secrets from kustomization file:

`microk8s kubectl apply -k .`

Create places for persistent volumes on database-node and allow access:

.. you can either (you may need to `sudo chmod +x volumes.sh`);

`sudo ./volumes.sh`

.. or,

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

`cd /home/ubuntu/shared/path/to/postgres-db-elastos-blockchains`

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

You can edit secret.yml but then you need to alter the redis-xyz.yml's and haskell.yml as the hash for postgres key will change. So you would have to find the hashes in the redis yml files and alter to match newly created key - ie with `microk8s kubectl apply -k .`, and then:

`microk8s kubectl delete deployments redis-cheirrs redis-cheirrs-oseer redis-a-horse haskell`

and restart from above. The deployments may be freely created and deleted at this stage as they are not programmed instances of Redis, more placeholders. Likewise with the Haskell webserver, it is an adaptable element which can readily be destroyed and recreated. The Haskell server generates its APIs automatically upon connection via the Haskell Key configuration which allows the server to connect and 'migrate' the schemae, tables, columns, sequences and functions etc directly from the postgres database.

(Track on master-node with `watch microk8s kubectl get pods`)

At this stage you should edit /var/lib/postgresql/data/pgdata/pg_hba.conf to allow access from the elastos blockchains pod, the Haskell webserver, and the 3 redis pods, by obtaining their ip addresses from:

`microk8s kubectl describe pods`,

and editing pg_hba.conf to include these addresses with /32 as the CIDR, and on trust basis.

_______________________________________________________________________

## TRUFFLE & Smart Contracts in Elastos/Ethereum: ##

The following is experimental:

In truffle-node terminal:

`sudo apt-get update`

`sudo apt-get install npm`

`sudo npm install -g truffle solc @truffle/hdwallet-provider`

`truffle init`

`nano truffle-config.js`

By deleting the comment "//"'s in the "development" section in "networks", you need to enable the development network to connect to the Elastos/Eth blockchain. Although the documentation at https://developer.elastos.org/elastos_core_services/guides/ethereum_smart_contracts/deploying_smart_contracts/ gives the Eth rpc port number in the Elastos System as 21636, in Kubernetes that number refers only to the port on the Elastos Ethereum Blockchain Container, and is inaccessible at that number from outside the container.

However if you issue (on a second master-node terminal):

`microk8s kubectl get services`

you will see there is a nodePort number associated with each Elastos port. The nodePort number corresponding to Elastos Port Number 21636 should be inserted in the network config for Truffle. This port number alters each time you rebuild the blockchains. The network_id should be "*", and the host Ip-Address to use is the vm (node) address of the blockchains-node - obtainable from:

`multipass list`, run on the Host computer.

The remaining edits required for truffle-config.js are on the latter webpage.

On that page is a link to the ELA/ETH "faucet" where we are supposed to obtain Test Ela/Eth. https://faucet.elaeth.io/ , however we found it failed repeatedly and we have zero Test ELA/ETH. :(   ... The answer seems to lie behind the configuration of the Test ELA/ETH Blockchain because it requires access to/from the Internet to link with the faucet webservice. That interconnectivity appears to be absent currently, with Testnet ELA/ETH quoted publicly alongside other published network id's (from other organisations attaching to Ethereum) as "2". However, the current develap binaries result in network id = "3" as default configured value. As the network id's do not match, we are disconnected from the ELA/ETH faucetat this stage.

We did find that we could successfully connect to the Truffle development network (as paupers) with the above nodePort config. This means we are connected to the Elastos Blockchains, after running

`truffle console --network development`.

We were also able to obtain an Eth Account Address with:

`web3.eth.personal.newAccount("MY_PASSWORD")`.

We then inserted that Account Address into the truffle-config.js file as described on the above Elastos webpage.

At the very least this means we have managed to successfully construct a fully connected Kubernetes backend for the Database and Blockchains (based on Fully Replicated Postgresql and the Elastos Develap Binaries) with a Truffle node upon which programming of solidity smart contracts would be able to occur against the Blockchains, given we had some Test ELA/ETH. We have webservers in the form of caching Redis Servers unprogrammed but ready, and a general-purpose Haskell language-based server from the Postgrest project, to use until we have Redis operating. The installation of Database/Blockchains/Servers and Truffle Node is fairly stable although it has fallen over once since generation. We are able to launch a connected Truffle Development Environment on the truffle-node, it's just the ELA/ETH Test Faucet is either not working or holds secrets we have yet to uncover .. by design we suspect.

Nevertheless you can continue to develop Ethereum Smart Contracts using a local Ganache/Truffle system on the Host in a directory accessible to the truffle-node.

Install Ganache by googling the name and then !!CHANGE PATH TO SUIT YOURSELF!! 

`mkdir -p path/to/directory/truffle-project && cd path/to/directory/truffle-project` 

on Host.

`sudo apt-get update`

`sudo apt-get install npm`

`sudo npm install -g truffle solc @truffle/hdwallet-provider`

`truffle init`

`nano truffle-config.js`

.. uncomment Development Network section and insert "localhost" as host and 7545 as port with "*" as network-id.

.. save and exit.

You can now run the Ganache starter you would have downloaded earlier.

Congratulatioons you are ready to code and compile solidity smart contracts on your host and transfer them to the truffle-node terminal to run on the local Ethereum Blockchain on Kubernetes. (when the network-id for develap binaries version matches public testnet network-id.)
