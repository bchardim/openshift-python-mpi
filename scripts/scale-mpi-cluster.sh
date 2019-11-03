#!/bin/bash

REP=$1

echo ""
echo "#######################################################"
echo "# Scale mpi cluster                                   #"
echo "#######################################################"
echo ""

oc scale dc mpi-master --replicas 0
oc wait dc mpi --for condition=available
oc scale dc mpi-master --replicas 1
oc wait dc mpi --for condition=available

oc scale dc mpi --replicas ${REP}
oc wait dc mpi --for condition=available
sleep $(echo "60 + $REP" | bc)

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
mpi_scripts_dir='/home/mpi/mpi-scripts'

echo "Pod list: $(echo ${mpi_pods_names} | tr '\n' ' ')"
echo "Pod count: ${mpi_pods_count}"

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
oc rsh --request-timeout=3600 ${mpi_pod_head} bash ${mpi_scripts_dir}/reconfigure-mpi-cluster.sh "${mpi_master_ip}" "${mpi_pods_ips}" "${mpi_pods_count}"
