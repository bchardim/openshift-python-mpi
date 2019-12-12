#!/bin/bash

# Redirect script output to logs
exec > /.ipython/profile_mpi/log/configure-mpi-cluster.log


while true    
do


    # Initial delay
    sleep 30

    # Profile config
    CMAP_DIR=/.ipython/configmap
    PROF_DIR=/.ipython/profile_mpi
    HOST_FL=/home/mpi/hosts
    REPL_FL=${PROF_DIR}/replicas
    MPI_RECONFIG=0 
    date

    echo ""
    echo "#######################################################"
    echo "# Check if MPI cluster needs reconfiguration          #"
    echo "#######################################################"
    echo ""

    # Calculate number of PODs running in mpi cluster
    POD_COUNT=$(dig ${MPI_SVC} A +search +short | wc -l)
    POD_LIST=$(dig ${MPI_SVC} A +search +short | tr '\n' ',' | sed 's/.$//')
    echo "Calculated POD_COUNT: '${POD_COUNT}'"
    HOST_COUNT=$(cat ${HOST_FL} | wc -l)
    echo "Calculated HOST_COUNT: '${HOST_COUNT}'"

    # Check all mpi nodes are in host file
    touch ${HOST_FL}
    for mpi in $(echo "${POD_LIST}" | tr ',' '\n')
    do
    	if [ $(grep -c "${mpi}" ${HOST_FL}) -eq 0 ]
        then		
	  MPI_RECONFIG=1   	
          echo "WARNING: MPI host '${mpi}' NOT found in '${HOST_FL}'. Reconfiguring mpi cluster."
	fi  
    done

    # Check POD_COUNT and HOST_COUNT are equal
    if [ "${POD_COUNT}" != "${HOST_COUNT}" ]
    then
	MPI_RECONFIG=1    
	echo "WARNING: POD_COUNT: '${POD_COUNT}' != HOST_COUNT: '${HOST_COUNT}'. Reconfiguring mpi cluster."    
    fi		

    # Check mpi cluster is running
    mkdir -p ${PROF_DIR}/pid && touch ${MPI_PID}
    MPI_PID=$(cat ${PROF_DIR}/pid/ipcluster.pid)
    MPI_PS_PID=$(pgrep ipcluster)
    if [ "${MPI_PID}" != "${MPI_PS_PID}" ]
    then
        MPI_RECONFIG=1
        echo "WARNING: MPI_PID: '${MPI_PID}' != MPI_PS_PID: '${MPI_PS_PID}'. Reconfiguring mpi cluster."    
    fi

    # Loop control
    if [ ${MPI_RECONFIG} -eq 0 ]
    then
        echo "MPI cluster does NOT need reconfiguration."
	continue
    fi	    

    echo ""
    echo "#######################################################"
    echo "# Generating MPI config                               #"
    echo "#######################################################"
    echo ""

    #
    # MPI architecture config
    #
    # $ mpirun -np 2 --bind-to core --map-by ppr:2:node:PE=4 ./a.out
    #                                                  | each task with 4 threads
    #         |number of tasks                         | to run 2 tasks per node each tasks with 4 threads
    #

    # Get mpi master pod ip
    MASTER_IP=$(grep ${HOSTNAME} /etc/hosts | awk -F" " '{print $1}')

    # Calculate number of tasks [-np]
    NP_COUNT=$((${POD_COUNT}*${MPI_POD_CPU}*${MPI_CPU_THREAD}))

    # Calculate number of slot per node [slot=]
    SLOT=$((${MPI_POD_CPU}*${MPI_CPU_THREAD}))

    echo "Pod list:           $(echo ${POD_LIST} | tr '\n' ' ')"
    echo "Pod count:          ${POD_COUNT}"
    echo "Nslot/node [slot=]: ${SLOT}"
    echo "Ntask count [-np]:  ${NP_COUNT}"

    echo ""
    echo "#######################################################"
    echo "# Reconfigure mpi cluster                             #"
    echo "#######################################################"
    echo ""

    # Stop mpi cluster
    ipcluster stop --profile=mpi
    ipcluster stop
    rm -rf ~/.ipython/profile_mpi

    # Create mpi cluster profile
    ipython3 profile create --parallel --profile=mpi
    jupyter serverextension enable --py ipyparallel
    jupyter nbextension disable --py ipyparallel

    # Create mpi config from configmaps
    for file in $(ls -1 $CMAP_DIR/)
    do
        cat ${CMAP_DIR}/${file} | sed -e "s/_MASTER_IP_/${MASTER_IP}/" -e "s/_NTASK_/${NP_COUNT}/" -e "s/_SLOT_/${SLOT}/" -e "s/_NTHREAD_/${MPI_CPU_THREAD}/" > ${PROF_DIR}/${file}
    done

    # Create mpi host file
    > ${HOST_FL} 
    for host in $(echo "${POD_LIST}" | tr ',' '\n')
    do
        echo "${host} slots=${SLOT} max-slots=${SLOT}" >> ${HOST_FL}
    done

    # Run mpi cluster
    echo "Running 'ipcluster start -n ${NP_COUNT} --profile=mpi --log-to-file --debug' [Log: .ipython/profile_mpi/log]"
    nohup ipcluster start -n ${NP_COUNT} --profile=mpi --log-to-file --debug &


done
