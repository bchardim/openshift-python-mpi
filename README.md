# openshift-python-mpi

## OpenShift
Instructions for setting this up on OpenShift

### Set needed environment variables
```bash
project_name=mpi-example
mpi_base_image_uri=
```

| variable              | description
|-----------------------|------------
| project\_name         | name of the project to generate
| mpi\_base\_image\_uri | url to where this project is stored


### Set up the project

Get the project
```bash
git clone ${mpi_base_image_uri}
cd openshift-python-mpi
```

Create the OpenShift project and intitial resources
```bash
oc new-project ${project_name}
oc process -f openshift/mpi-template.yml -p MPI_BASE_IMAGE_URI=${mpi_base_image_uri} | oc create -f -
```

Create the SSH information
```bash
./generate-ssh-configs.sh
./openshift/create-config-maps-and-secrets.sh
```

### Run MPI Job

Run a sample job against 10 pods
```bash
oc scale dc mpi --replicas 10
oc wait dc mpi --for condition=available

./openshift/run-mpi-script-against-ocp-mpi-pods.sh sample-scripts/mpi-hello-world.py

oc scale dc mpi --replicas 0
```

## Docker-compose
Instrucitons for setting this up on docker-compose.

**WARNING**: with all of the refactor for OpenShift the docker-compose use case is currently broken and will need to be updated to work with the new way of doing things. IE, dyanmically generating host key files, new directory structure, dynamically uplading scripts to containers, etc.
