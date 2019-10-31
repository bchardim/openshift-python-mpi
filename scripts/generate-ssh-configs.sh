#!/usr/bin/env bash

node=mpi
mkdir -p ssh/${node}
ssh-keygen -q -t rsa -f ssh/${node}/mpi_identity -N ''
cp ssh/${node}/mpi_identity.pub ssh/${node}/authorized_keys
cat > ssh/${node}/config <<EOL
Host *
    Port 2022
    User mpi
    IdentityFile ~/.ssh/mpi_identity
    StrictHostKeyChecking no
EOL
