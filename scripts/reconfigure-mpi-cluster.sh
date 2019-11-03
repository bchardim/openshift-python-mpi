#!/bin/bash

MASTER_IP=$1
WORKER_IPS=$2
NPROC=$3

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

cat > ~/.ipython/profile_mpi/ipcluster_config.py << HOSTEOF
c.IPClusterEngines.engine_launcher_class = 'MPIEngineSetLauncher'
c.MPILauncher.mpi_args = ["-hostfile", "/home/mpi/hosts", "-do-not-resolve"]
c.MPILauncher.mpi_cmd = ['mpirun']
c.MPIControllerLauncher.controller_args = ['--ip=${MASTER_IP}']
c.IPClusterStart.delay = 10
c.LocalEngineSetLauncher.delay = 10
c.IPClusterStart.early_shutdown = 90
c.IPClusterStart.log_level = 30
HOSTEOF

cat > ~/.ipython/profile_mpi/ipengine_config.py << ENGEOF
c.MPI.use = 'mpi4py'
c.EngineFactory.ip = '${MASTER_IP}'
c.IPEngineApp.wait_for_url_file = 30
c.EngineFactory.timeout = 30
c.IPEngineApp.log_level = 30
ENGEOF

cat > ~/.ipython/profile_mpi/ipcontroller_config.py  << CONEOF
c.HubFactory.ip = '${MASTER_IP}'
c.HubFactory.registration_timeout = 30
###c.IPControllerApp.reuse_files = True
c.IPControllerApp.log_level = 30
CONEOF

> /home/mpi/hosts 
for i in $(echo "${WORKER_IPS}" | tr ',' '\n')
do
    echo "${i} slots=1" >> /home/mpi/hosts
done

ipcluster start -n ${NPROC} --profile=mpi --debug
