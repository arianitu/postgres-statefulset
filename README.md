# postgres-statefulset
This is an example of using Kubernetes StatefulSets to get a Postgres instance running with replication enabled. This also uses the [standard Postgres container](https://github.com/docker-library/postgres). Blog article [here](https://stacksoft.io/blog/postgres-statefulset/)

The work here is based off the official documentation here https://wiki.postgresql.org/wiki/Streaming_Replication

## Configuration

1. Edit `config/secret.yml` with the Postgres database password and the replication password 
2. Run `kubectl apply -f config/secret.yml` and then `cd config && ./create_configmap.sh`

Note, replication password is used to connect to the master and stream updates to the replica. It just needs to be a random password. 

## Running

Running this example is easy!

### Start Master servers

Run `kubectl apply -f statefulset-master.yml` and wait for Master to be running

### Start Replica server

Run `kubectl apply -f statefulset-replica.yml` and wait for Replica to be running

If you run `kubectl logs -f postgres-replica-0`, you can see in the logs that it starts replication:

```
2019-01-08 05:07:01.035 UTC [24] LOG:  started streaming WAL from primary at 0/6000000 on timeline 1
```

That's it, you have a full Postgres master + replicating server that's ready to use in production. 

#### Multiple Replicas

You can also set replicas to more than 1 if you want N replicas. 

### Motivation

I was using Helm to manage Postgres, but they switched to `bitnami/postgresql` instead of the standard `postgres`. Also, upon upgrading, I could not use my existing helm setup to get replication working.

Lately I've realized it's just easier to write my own definitions instead of messing around with Helm charts. 
