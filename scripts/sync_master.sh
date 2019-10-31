notebook_dir=/home/mpi/notebooks
app_name=mpi
mpi_pods_master=`oc get pod -l app=${app_name}-master -o wide`
mpi_pods_names=`echo "${mpi_pods_master}" | awk 'FNR > 1 {print $1}'`
oc rsync ${mpi_pods_names}:${notebook_dir}/ ./notebooks/ 
