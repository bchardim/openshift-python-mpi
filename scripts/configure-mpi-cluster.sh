#!/bin/bash

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
MASTER_IP=$(grep ${HOSTNAME} /etc/hosts | awk -F" " '{print $1}')

# Set number of threats per worker core
# MPI_CPU_THREAD=2 # for overcommited OCP clusters, only 2 worker cpus are used
# MPI_CPU_THREAD=3 # to force load distribution across all worker cpus 

# Calculate number of PODs running in mpi cluster
POD_COUNT=$(dig ${MPI_SVC} A +search +short | wc -l)
POD_LIST=$(dig ${MPI_SVC} A +search +short | tr '\n' ',' | sed 's/.$//')

# Calculate number of tasks [-np]
NP_COUNT=$((${POD_COUNT}*${MPI_POD_CPU}*${MPI_CPU_THREAD}))

# Calculate number of slot per node [slot=]
SLOT=$((${MPI_POD_CPU}*${MPI_CPU_THREAD}))

echo "Pod list:           $(echo ${POD_LIST} | tr '\n' ' ')"
echo "Pod count:          ${POD_COUNT}"
echo "Nslot/node [slot=]: ${SLOT}"
echo "Ntask count [-np]:  ${NP_COUNT}"

echo ""
echo "#######################################################"
echo "# Reconfigure mpi cluster                             #"
echo "#######################################################"
echo ""

# Profile config
CMAP_DIR=/.ipython/configmap
PROF_DIR=/.ipython/profile_mpi

# Stop mpi cluster
ipcluster stop --profile=mpi
ipcluster stop
rm -rf ~/.ipython/profile_mpi

# Create mpi cluster profile
ipython3 profile create --parallel --profile=mpi
jupyter serverextension enable --py ipyparallel
# The following disables mpi cluster control from notebook
# We prefear mpi cluster control from OCP
jupyter nbextension disable --py ipyparallel

# Create mpi config from configmaps
for file in $(ls -1 $CMAP_DIR{}/)
do
    sed -e 's/_MASTER_IP_/${MASTER_IP}/' ${CMAP_DIR}/$file > ${PROF_DIR}/$file
    sed -e 's/_NTASK_/${NP_COUNT}/' ${CMAP_DIR}/$file > ${PROF_DIR}/$file
    sed -e 's/_SLOT_/${SLOT}/' ${CMAP_DIR}/$file > ${PROF_DIR}/$file
    sed -e 's/_NTHREAD_/${MPI_CPU_THREAD}/' ${CMAP_DIR}/$file > ${PROF_DIR}/$file
done

# Create mpi host file
> /home/mpi/hosts 
for i in $(echo "${POD_LIST}" | tr ',' '\n')
do
	echo "${i} slots=${SLOT} max-slots=${SLOT}" >> /home/mpi/hosts
done

# Run mpi cluster
echo "Running 'ipcluster start -n ${NP_COUNT} --profile=mpi --log-to-file --debug' [Log: .ipython/profile_mpi/log]"
ipcluster start -n ${NP_COUNT} --profile=mpi --log-to-file --debug

