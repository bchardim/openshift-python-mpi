#!/bin/bash

app_name=mpi

mpi_pods=`oc get po -l app=${app_name} -o wide`
mpi_pods_names=`echo "${mpi_pods}" | awk 'FNR > 1 {print $1}'`
mpi_pods_ips=`echo "${mpi_pods}" | awk 'FNR > 1 {print $6}'`
mpi_pods_count=`echo "${mpi_pods_ips}" | wc -l`
mpi_pod_head=`echo "${mpi_pods}" | awk 'FNR > 1 {print $1}' | head -n 1`
mpi_host_list=`echo "${mpi_pods_ips}" | tr '\n' ',' | sed 's/.$//'`
mpi_scripts_dir='/home/sds/mpi-scripts'

echo "rsync script parent directory to MPI pods"
for mpi_pod in ${mpi_pods_names}; do
  echo "${mpi_pod}"
  oc rsync `dirname $1` ${mpi_pod}:${mpi_scripts_dir}
  echo
done

echo
echo "run mpi script"
oc rsh ${mpi_pod_head} mpirun -n ${mpi_pods_count} -H ${mpi_host_list} scl enable rh-python35 ${mpi_scripts_dir}/$1
