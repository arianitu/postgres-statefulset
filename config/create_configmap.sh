kubectl create configmap postgres --namespace smartapp --from-file=postgres.conf --from-file=master.conf --from-file=replica.conf --from-file=pg_hba.conf --from-file=create-replica-user.sh
