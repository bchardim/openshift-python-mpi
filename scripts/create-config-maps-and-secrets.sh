#!/bin/bash

oc create secret generic mpi-identity --type=kubernetes.io/ssh-auth --from-file=ssh-privatekey=./ssh/mpi/mpi_identity --from-file=ssh-publickey=./ssh/mpi/mpi_identity.pub
oc create configmap mpi-ssh-config --from-file=ssh-authorized-keys=./ssh/mpi/authorized_keys --from-file=ssh-config=./ssh/mpi/config
oc create configmap mpi-cluster-config --from-file=mpi-ipcluster-config=.ipython/profile_mpi/ipcluster_config.py --from-file=mpi-ipengine-config=.ipython/profile_mpi/ipengine_config.py --from-file=mpi-ipcontroller-config=.ipython/profile_mpi/ipcontroller_config.py
