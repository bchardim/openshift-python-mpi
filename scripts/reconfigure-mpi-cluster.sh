#!/bin/bash

MASTER_IP=$1
WORKER_IPS=$2
NPROC=$3

echo ""
echo "#######################################################"
echo "# Reconfigure mpi cluster                             #"
echo "#######################################################"
echo ""

ipython3 profile create --parallel --profile=mpi
jupyter serverextension enable --py ipyparallel
jupyter nbextension enable --py ipyparallel

cat > ~/.ipython/profile_mpi/ipcluster_config.py << HOSTEOF
c.IPClusterEngines.engine_launcher_class = 'MPIEngineSetLauncher'
c.MPILauncher.mpi_args = ["-hostfile", "/home/sds/hosts"]
c.MPILauncher.mpi_cmd = ['mpirun']
c.MPIControllerLauncher.controller_args = ['--ip=${MASTER_IP}']
HOSTEOF

cat > ~/.ipython/profile_mpi/ipcontroller_config.py  << EOF
c.HubFactory.ip = '${MASTER_IP}'
EOF

> /home/sds/hosts 
for i in $(echo "${WORKER_IPS}" | tr ',' '\n')
do
    echo "${i} slots=1" >> /home/sds/hosts
done

ipcluster stop --profile=mpi
ipcluster stop
rm ~/.ipython/profile_mpi/pid/*
ipcluster start -n ${NPROC} --profile=mpi --debug

