# openshift-python-mpi

## OpenShift
Instructions for setting this up on OpenShift

### Set up the project

Get the project
```bash
git clone https://github.com/bchardim/openshift-python-mpi
cd openshift-python-mpi
```

Create Openshift Project
```bash
oc new-project gw-learning
```

Create the persistent shared storage needed for MPI cluster operation. In this case we are going to use NFS in RWX mode.
```bash
oc create -f storage/nfs-mpi-pv.yaml
persistentvolume/nfs-pv-mpi created

oc create -f storage/nfs-mpi-pvc.yaml
persistentvolumeclaim/nfs-pvc-mpi created

oc get pvc
NAME          STATUS   VOLUME       CAPACITY   ACCESS MODES   STORAGECLASS   AGE
nfs-pvc-mpi   Bound    nfs-pv-mpi   2Gi        RWX                           3s
```

Create the SSH information
```bash
bash scripts/generate-ssh-configs.sh
bash scripts/create-config-maps-and-secrets.sh
```
Create the OpenShift resources
```bash
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


