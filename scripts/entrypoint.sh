#!/usr/bin/env bash

# NOTE: this script is running as the user that OpenShift assigns at runtime
# in this case its the USER sds, which will be in the root group,
# however the id is not known until runtime
# so update the sds user's id to match the runtime user id
#echo -e ",s/10001/`id -u`/g\\012 w" | ed -s /etc/passwd

# now start setting up resources needed by sds user

# sds user ~/.ssh
mkdir -p /home/sds/.ssh
chmod 700 /home/sds/.ssh
chmod 600 /home/sds/.ssh/*

# finally start sshd
exec /usr/sbin/sshd -D
