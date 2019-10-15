# run example mpi with head+worker1+worker2


# TLDR

    $ cd centos

    # this will take a few minutes .. builds from source
    $ docker-compose build

    $ docker-compose up -d

    $ docker-compose exec head /bin/bash
    $ mpirun -n 3 -H head,worker1,worker2 /home/sds/src/mpi-hello-world.py

    Hello! I'm rank 0 from 3 running in total...
    Hello! I'm rank 1 from 3 running in total...
    Hello! I'm rank 2 from 3 running in total...
