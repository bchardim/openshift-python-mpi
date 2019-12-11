#!/bin/bash

# Reading number of mpi replicas
NTASK=$(cat /.ipython/replicas)

echo ""
echo "#######################################################"
echo "# Generating MPI config                               #"
echo "#######################################################"
echo ""

#
# MPI architecture config
#
# $ mpirun -np 2 --bind-to core --map-by ppr:2:node:PE=4 ./a.out
#                                                  | each task with 4 threads
#         |number of tasks                         | to run 2 tasks per node each tasks with 4 threads
#

# Get mpi master pod ip
MASTER_IP=$(grep $(cat /etc/hostname) /etc/hosts | awk -F" " '{print $1}')

# Set number of threats per worker core
# NTHREAD_ENV=2 # for overcommited OCP clusters, only 2 worker cpus are used
# NTHREAD_ENV=3 # to force load distribution across all worker cpus 

# Calculate number of PODs running in mpi cluster
POD_COUNT=$(dig ${MPI_SVC_ENV} A +search +short | wc -l)
POD_LIST=$(dig ${MPI_SVC_ENV} A +search +short | tr '\n' ',' | sed 's/.$//')

# Calculate number of tasks [-np]
NP_COUNT=$((${POD_COUNT}*${POD_CPU_ENV}*${NTHREAD}))

# Calculate number of slot per node [slot=]
SLOT=$((${POD_CPU_ENV}*${NTHREAD_ENV}))

echo "Pod list:           $(echo ${POD_LIST} | tr '\n' ' ')"
echo "Pod count:          ${POD_COUNT}"
echo "Nslot/node [slot=]: ${SLOT}"
echo "Ntask count [-np]:  ${NP_COUNT}"

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
for i in $(echo "${POD_LIST}" | tr ',' '\n')
do
	echo "${i} slots=${SLOT} max-slots=${SLOT}" >> /home/mpi/hosts
done

echo "Running 'ipcluster start -n ${NTASK} --profile=mpi --log-to-file --debug' [Log: .ipython/profile_mpi/log]"
ipcluster start -n ${NTASK} --profile=mpi --log-to-file --debug

