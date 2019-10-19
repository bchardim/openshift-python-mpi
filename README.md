# openshift-python-mpi

## OpenShift
Instructions for setting this up on OpenShift

### Set up the project

Get the project
```bash
git clone https://github.com/bchardim/openshift-python-mpi
cd openshift-python-mpi
```
Create the SSH information
```bash
bash scripts/generate-ssh-configs.sh
bash scripts/create-config-maps-and-secrets.sh
```
Create the OpenShift project and intitial resources
```bash
oc new-project gw-learning
oc process -f mpi-template.yml -p MPI_BASE_IMAGE_URI=https://github.com/bchardim/openshift-python-mpi | oc create -f -
```

### Run MPI Job

Run a sample job against 10 pods
```bash
oc scale dc mpi --replicas 10
oc wait dc mpi --for condition=available

cd scripts
./run-mpi-script-against-ocp-mpi-pods.sh mpi/mpi-hello-world.py

oc scale dc mpi --replicas 0
```


## References
https://github.com/itewk/openshift-mpi-example


