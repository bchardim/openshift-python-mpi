#!/usr/bin/env bash

node=sds
mkdir -p ssh/${node}
ssh-keygen -q -t rsa -f ssh/${node}/sds_identity -N ''
cp ssh/${node}/sds_identity.pub ssh/${node}/authorized_keys
cat > ssh/${node}/config <<EOL
Host *
    Port 2022
    User sds
    IdentityFile ~/.ssh/sds_identity
    StrictHostKeyChecking no
EOL
