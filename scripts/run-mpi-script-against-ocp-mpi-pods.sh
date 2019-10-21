#!/bin/bash


echo ""
echo "#######################################################"
echo "# Gathering Openshift Configuration                   #"
echo "#######################################################"
echo ""

app_name=mpi
mpi_pods=`oc get pod -l app=${app_name} -o wide`
mpi_pods_master=`oc get pod -l app=${app_name}-master -o wide`
mpi_pods_names=`echo "${mpi_pods}" | awk 'FNR > 1 {print $1}'`
mpi_pods_ips=`echo "${mpi_pods}" | awk 'FNR > 1 {print $6}'`
mpi_pods_count=`echo "${mpi_pods_ips}" | wc -l`
mpi_pod_head=`echo "${mpi_pods_master}" | awk 'FNR > 1 {print $1}' | head -n 1`
mpi_host_list=`echo "${mpi_pods_ips}" | tr '\n' ',' | sed 's/.$//'`
mpi_scripts_dir='/home/sds/mpi-scripts'

echo "Pod list: $(echo ${mpi_pods_names} | tr '\n' ' ')"
echo "Pod count: ${mpi_pods_count}"

echo ""
echo "#######################################################"
echo "# Rsync mpi script to all pods                        #"
echo "#######################################################"
echo ""

echo "Rsync script parent directory to MPI pods"
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

echo
echo "Run mpi script"
echo "oc rsh --request-timeout=3600 ${mpi_pod_head} mpirun -np ${mpi_pods_count} -H ${mpi_host_list} scl enable rh-python36 \"bash -c '${mpi_scripts_dir}/$1 $2 $3'\""
oc rsh --request-timeout=3600 ${mpi_pod_head} mpirun -np ${mpi_pods_count} -H ${mpi_host_list} scl enable rh-python36 "bash -c '${mpi_scripts_dir}/$1 $2 $3'"
