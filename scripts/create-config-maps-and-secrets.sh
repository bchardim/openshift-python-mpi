#!/bin/bash

oc create secret generic sds-identity --type=kubernetes.io/ssh-auth --from-file=ssh-privatekey=./ssh/sds/sds_identity --from-file=ssh-publickey=./ssh/sds/sds_identity.pub
oc create configmap sds-ssh-config --from-file=ssh-authorized-keys=./ssh/sds/authorized_keys --from-file=ssh-config=./ssh/sds/config
