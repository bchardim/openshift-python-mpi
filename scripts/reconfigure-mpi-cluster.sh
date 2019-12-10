#!/bin/bash

MASTER_IP=$1
WORKER_IPS=$2
NTASK=$3
SLOT=$4
NTHREAD=$5

echo ""
echo "#######################################################"
echo "# Reconfigure mpi cluster                             #"
echo "#######################################################"
echo ""

ipcluster stop --profile=mpi
ipcluster stop
rm -rf ~/.ipython/profile_mpi

ipython3 profile create --parallel --profile=mpi
jupyter serverextension enable --py ipyparallel
# The following disables mpi cluster control from notebook
# We prefear mpi cluster control from OCP
jupyter nbextension disable --py ipyparallel

> /home/mpi/hosts 
for i in $(echo "${WORKER_IPS}" | tr ',' '\n')
do
	echo "${i} slots=${SLOT} max-slots=${SLOT}" >> /home/mpi/hosts
done

echo "Running 'ipcluster start -n ${NTASK} --profile=mpi --log-to-file --debug' [Log: .ipython/profile_mpi/log]"
ipcluster start -n ${NTASK} --profile=mpi --log-to-file --debug

