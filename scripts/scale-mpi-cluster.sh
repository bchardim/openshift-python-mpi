#!/bin/bash

REP=$1

echo ""
echo "#######################################################"
echo "# Scale mpi cluster                                   #"
echo "#######################################################"
echo ""

oc scale dc mpi --replicas ${REP}
oc wait dc mpi --for condition=available --timeout=300s
sleep $(echo "60 + 2*$REP" | bc)

echo ""
echo "#######################################################"
echo "# Reading new pod distribution                        #"
echo "#######################################################"
echo ""

app_name=mpi
mpi_pods=`oc get pod -l app=${app_name} -o wide`
mpi_pods_master=`oc get pod -l app=${app_name}-master -o wide`
mpi_master_ip=`echo "${mpi_pods_master}" | awk 'FNR > 1 {print $6}' | head -n 1`
mpi_pods=${mpi_pods_master}${mpi_pods}
mpi_pods_names=`echo "${mpi_pods}" | awk 'FNR > 1 {print $1}'`
mpi_pods_ips=`echo "${mpi_pods}" | awk 'FNR > 1 {print $6}'`
mpi_pods_count=`echo "${mpi_pods_ips}" | wc -l`
mpi_pod_head=`echo "${mpi_pods_master}" | awk 'FNR > 1 {print $1}' | head -n 1`
mpi_host_list=`echo "${mpi_pods_ips}" | tr '\n' ',' | sed 's/.$//'`
mpi_pods_cpu=`oc get dc/${app_name} -o yaml | grep -A4 requests: | grep cpu: | cut -d'"' -f2`
mpi_scripts_dir='/home/mpi/mpi-scripts'

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

# Core hyperthreading
# Set number of threats per worker core
mpi_core_thread=1

# Calculate number of tasks [-np]
mpi_np_count=$((${mpi_pods_count}*${mpi_pods_cpu}*${mpi_core_thread}))

# Calculate number of slot per node [slot=]
mpi_slot_count=$((${mpi_pods_cpu}*${mpi_core_thread}))

echo "Pod list:           $(echo ${mpi_pods_names} | tr '\n' ' ')"
echo "Pod count:          ${mpi_pods_count}"
echo "Nslot/node [slot=]: ${mpi_slot_count}"
echo "Ntask count [-np]:  ${mpi_np_count}"

echo ""
echo "#######################################################"
echo "# Rsync mpi scripts to all pods                       #"
echo "#######################################################"
echo ""
for mpi_pod in ${mpi_pods_names}; do
  echo "${mpi_pod}"
  oc rsync `dirname $1` ${mpi_pod}:${mpi_scripts_dir}
  echo
done

echo ""
echo "#######################################################"
echo "# Run reconfigure-mpi-cluster.sh in master            #"
echo "#######################################################"
echo ""
oc rsh --request-timeout=3600 ${mpi_pod_head} bash ${mpi_scripts_dir}/reconfigure-mpi-cluster.sh "${mpi_master_ip}" "${mpi_host_list}" "${mpi_np_count}" "${mpi_slot_count}" "${mpi_core_thread}"
