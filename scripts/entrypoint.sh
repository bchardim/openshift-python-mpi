#!/usr/bin/env bash

# Config
default_mpi_uid=1001
actual_mpi_uid=`id -u`
mpi_home_dir='/home/mpi'
temp_mpi_identity_dir='/etc/ssh/mpi'
temp_notebooks_dir='/notebooks'
container_ip=$(awk '/32 host/ { print f } {f=$2}' <<< "$(</proc/net/fib_trie)" | grep -v "^127" | sort -u)

# update the mpi user with the id provided by openshift
# cant use inplace sed because of tmp file issue
#
# NOTE: had to do `echo ${var}` syntax in sed because of some weird problem where
#       using ${} directly in sed casued the file contents to always be empty
echo "Set MPI UID from ${default_mpi_uid} to ${actual_mpi_uid}"
regex_mpi_home_dir=$(printf '%s\n' "${mpi_home_dir}" | sed 's/[\&/]/\\&/g')
cat /etc/passwd | sed "s/^mpi:x:`echo ${default_mpi_uid}`.*/mpi:x:`echo ${actual_mpi_uid}`:0::`echo ${regex_mpi_home_dir}`:\/bin\/bash/" > /etc/passwd

echo "Create home directory"
mkdir -p "${mpi_home_dir}"

echo "Generate the container specfic host keys for sshd"
ssh-keygen -q -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''
ssh-keygen -q -t dsa -f /etc/ssh/ssh_host_dsa_key -N ''
ssh-keygen -q -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ''
ssh-keygen -q -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N ''
chmod 600 /etc/ssh/ssh_*key

echo "Ensure the .ssh directory exists"
mkdir -p "${mpi_home_dir}/notebooks"
chmod 700 "${mpi_home_dir}/notebooks"
mkdir -p "${mpi_home_dir}/.ssh"
chmod 700 "${mpi_home_dir}/.ssh"

# the MPI identity ssh keys are mounted from secrets into a temporary directory
# so they can then be copied to the /home/mpi/.ssh/ directory with the correct permisisons.
#
# This is done this way because if mounting the keys directly into home directory they will
# always be symlinks with 0777 permissions no matter the permissions set on the files
# they link to
echo "Copy the MPI identity key files into /home/mpi/.ssh/ and set file permisions"
cp -H "${temp_mpi_identity_dir}/"* "${mpi_home_dir}/.ssh/"
chmod 600 "${mpi_home_dir}/.ssh/"*

echo 'Copy notebooks files'
cp -H "${temp_notebooks_dir}/"* "${mpi_home_dir}/notebooks/"
chmod 700 "${mpi_home_dir}/notebooks/"

echo 'Set home directory permisions and env'
chown mpi:root "${mpi_home_dir}"
chmod 750 "${mpi_home_dir}"
export HOME=${mpi_home_dir} && cd ${mpi_home_dir} && ln -sf /.ipython .

# Start sshd and jupyter-notebook
if [[ $HOSTNAME =~ .*master.* ]]
then
  echo "Start sshd at master pod"
  nohup /usr/sbin/sshd &
  echo "Start jupyter-notebook at master pod" 
  exec jupyter-notebook --ip ${container_ip} --port 8888 --no-browser --notebook-dir ${mpi_home_dir} --NotebookApp.token=''
else
  echo "Start sshd at mpi pod"	 
  exec /usr/sbin/sshd -D
fi

