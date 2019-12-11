c.IPClusterEngines.engine_launcher_class = 'MPIEngineSetLauncher'
c.MPILauncher.mpi_args = [ "-np","_NTASK_}","-bind-to", "core", "--map-by", "ppr:_SLOT_}:node:pe=_NTHREAD_}", "-hostfile", "/home/mpi/hosts", "-do-not-resolve"]
c.MPILauncher.mpi_cmd = ['mpirun']
c.MPIControllerLauncher.controller_args = ['--ip=_MASTER_IP_']
c.IPClusterStart.delay = 10
c.LocalEngineSetLauncher.delay = 10
c.IPClusterStart.early_shutdown = 90
c.IPClusterStart.log_level = 30
