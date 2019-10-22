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

Run a sample job against 10 mpi pods + master
```bash
oc scale dc mpi --replicas 10
oc wait dc mpi --for condition=available

cd scripts
./run-mpi-script-against-ocp-mpi-pods.sh mpi/mpi-hello-world.py

oc scale dc mpi --replicas 1
```

Calculate pi using 11000000 points against 10 mpi pods + master
```bash
oc scale dc mpi --replicas 10
oc wait dc mpi --for condition=available

cd scripts
./run-mpi-script-against-ocp-mpi-pods.sh mpi/pi_mpi_calc.py 11000000
...
...
Calculated pi is 3.1415404000, error is 0.0000522536

oc scale dc mpi --replicas 1
```



## References
https://github.com/itewk/openshift-mpi-example


