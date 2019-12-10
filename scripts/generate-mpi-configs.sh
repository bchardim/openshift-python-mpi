#!/usr/bin/env bash

mkdir -p .ipython/profile_mpi
cat > .ipython/profile_mpi/ipcluster_config.py << HOSTEOF
c.IPClusterEngines.engine_launcher_class = 'MPIEngineSetLauncher'
c.MPILauncher.mpi_args = [ "-np","_NTASK_}","-bind-to", "core", "--map-by", "ppr:_SLOT_}:node:pe=_NTHREAD_}", "-hostfile", "/home/mpi/hosts", "-do-not-resolve"]
###c.MPILauncher.mpi_args = [ "-hostfile", "/home/mpi/hosts", "-do-not-resolve"]
c.MPILauncher.mpi_cmd = ['mpirun']
c.MPIControllerLauncher.controller_args = ['--ip=_MASTER_IP_']
c.IPClusterStart.delay = 10
c.LocalEngineSetLauncher.delay = 10
c.IPClusterStart.early_shutdown = 90
c.IPClusterStart.log_level = 30
HOSTEOF

cat > .ipython/profile_mpi/ipengine_config.py << ENGEOF
c.MPI.use = 'mpi4py'
c.EngineFactory.ip = '_MASTER_IP_'
c.IPEngineApp.wait_for_url_file = 30
c.EngineFactory.timeout = 60
c.IPEngineApp.log_level = 30
ENGEOF

cat > .ipython/profile_mpi/ipcontroller_config.py  << CONEOF
c.HubFactory.ip = '_MASTER_IP_'
c.HubFactory.registration_timeout = 60
###c.IPControllerApp.reuse_files = True
c.IPControllerApp.log_level = 30
CONEOF

