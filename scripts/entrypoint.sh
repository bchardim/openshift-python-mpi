#!/usr/bin/env bash

default_sds_uid=10001
actual_sds_uid=`id -u`
sds_home_dir='/home/sds'
temp_sds_identity_dir='/etc/ssh/sds'

# update the sds user with the id provided by openshift
# cant use inplace sed because of tmp file issue
#
# NOTE: had to do `echo ${var}` syntax in sed because of some weird problem where
#       using ${} directly in sed casued the file contents to always be empty
echo "Set SDS UID from ${default_sds_uid} to ${actual_sds_uid}"
regex_sds_home_dir=$(printf '%s\n' "${sds_home_dir}" | sed 's/[\&/]/\\&/g')
cat /etc/passwd | sed "s/^sds:x:`echo ${default_sds_uid}`.*/sds:x:`echo ${actual_sds_uid}`:0::`echo ${regex_sds_home_dir}`:\/bin\/bash/" > /etc/passwd

echo "Create home directory"
mkdir -p "${sds_home_dir}"

#echo "Generate the container specfic host keys for sshd"
ssh-keygen -q -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''
ssh-keygen -q -t dsa -f /etc/ssh/ssh_host_dsa_key -N ''
ssh-keygen -q -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ''
ssh-keygen -q -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N ''
chmod 600 /etc/ssh/ssh_*key

echo "Ensure the .ssh directory exists"
mkdir -p "${sds_home_dir}/notebooks"
chmod 700 "${sds_home_dir}/notebooks"
mkdir -p "${sds_home_dir}/.ssh"
chmod 700 "${sds_home_dir}/.ssh"

# the SDS identity ssh keys are mounted from secrets into a temporary directory
# so they can then be copied to the /home/sds/.ssh/ directory with the correct permisisons.
#
# This is done this way because if mounting the keys directly into home directory they will
# always be symlinks with 0777 permissions no matter the permissions set on the files
# they link to
echo "Copy the SDS identity key files into /home/sds/.ssh/ and set file permisions"
cp -H "${temp_sds_identity_dir}/"* "${sds_home_dir}/.ssh/"
chmod 600 "${sds_home_dir}/.ssh/"*

echo 'Set home directory permisions'
chown sds:root "${sds_home_dir}"
chmod 750 "${sds_home_dir}"

echo "Start sshd"
exec /usr/sbin/sshd -D

# Start jupyter-notebook only on master
if [[ $(hostname) =~ .*master.* ]]
then
  echo "Start jupyter-notebook only on master"	
  exec jupyter-notebook --ip 0.0.0.0 --port 8888 --no-browser
fi	

