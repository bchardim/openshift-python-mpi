#!/bin/bash


echo ""
echo "#######################################################"
echo "# Gathering Openshift Configuration                   #"
echo "#######################################################"
echo ""

app_name=mpi
mpi_pods=`oc get pod -l app=${app_name} -o wide`
mpi_pods_master=`oc get pod -l app=${app_name}-master -o wide`
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

# Set number of threats per worker core
# mpi_core_thread=2 # for overcommited OCP clusters
mpi_core_thread=3   # to force load distribution across all worker cpus 

# Calculate number of tasks [-np]
mpi_np_count=$((${mpi_pods_count}*${mpi_pods_cpu}*${mpi_core_thread}))

# Calculate number of slot per node [slot=]
mpi_slot_count=$((${mpi_pods_cpu}*${mpi_core_thread}))

mpi_host_list=`echo ${mpi_host_list}|sed -E "s/,|$/:${mpi_slot_count},/mg"`

echo "Pod list:           $(echo ${mpi_pods_names} | tr '\n' ' ')"
echo "Pod count:          ${mpi_pods_count}"
echo "Nslot/node [slot=]: ${mpi_slot_count}"
echo "Ntask count [-np]:  ${mpi_np_count}"

echo ""
echo "#######################################################"
echo "# Rsync mpi script to all pods                        #"
echo "#######################################################"
echo ""
for mpi_pod in ${mpi_pods_names}; do
  echo "${mpi_pod}"
  oc rsync `dirname $1` ${mpi_pod}:${mpi_scripts_dir}
  echo
done

echo ""
echo "#######################################################"
echo "# Run mpi scripts in parallel on all pod              #"
echo "#######################################################"
echo ""
mpi_opts="-np ${mpi_np_count} -bind-to core --map-by ppr:${mpi_slot_count}:node:pe=${mpi_core_thread} -mca btl ^openib -H ${mpi_host_list}"
echo "oc rsh --request-timeout=3600 ${mpi_pod_head} mpirun ${mpi_opts} ${mpi_scripts_dir}/$@"
oc rsh --request-timeout=3600 ${mpi_pod_head} mpirun ${mpi_opts} ${mpi_scripts_dir}/$@
