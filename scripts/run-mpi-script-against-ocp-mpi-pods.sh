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
mpi_cpu_count=$(echo "${mpi_pods_count} * ${mpi_pods_cpu}"|bc )
mpi_host_list=`echo ${mpi_host_list}|sed -E "s/,|$/:${mpi_pods_cpu},/mg"`
mpi_scripts_dir='/home/mpi/mpi-scripts'

#
# Scale factor to be tunned - mpi_cpu_slot
# For this environment we have 2 cores / proc
#
mpi_cores_per_proc=2

echo "Pod list: $(echo ${mpi_pods_names} | tr '\n' ' ')"
echo "Pod count: ${mpi_pods_count}"
echo "Nprocs count: ${mpi_cpu_count}"

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
mpi_opts="-np ${mpi_cpu_count} -bind-to core --map-by ppr:${mpi_cores_per_proc}:node:pe=${mpi_cores_per_proc} -mca btl ^openib -H ${mpi_host_list}"
echo "oc rsh --request-timeout=3600 ${mpi_pod_head} mpirun ${mpi_opts} ${mpi_scripts_dir}/$@"
oc rsh --request-timeout=3600 ${mpi_pod_head} mpirun ${mpi_opts} ${mpi_scripts_dir}/$@
