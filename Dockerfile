# vi: ft=Dockerfile
# FROM registry.fedoraproject.org/fedora-minimal:30
FROM quay.io/bchardim/fedora30-python-mpi:latest

RUN microdnf install --nodocs -y \
python3 \
python3-notebook \
python3-ipython \
python3-openmpi \
python3-ipyparallel \
python3-mpi4py-openmpi \
python3-mpi4py-mpich \
python3-numpy \
python3-scipy \
python3-matplotlib \
python3-scikit-learn \
python3-pandas \
python3-pydotplus \
python3-pydot \
graphviz-python3 \
graphviz \
dnf \
rsync \
gcc \
gcc-c++ \
openmpi \
mpi4py-common \
openssh \
openssh-server \
openssh-clients \
openssl-libs \
bind-utils \
&& microdnf update \
&& microdnf clean all \
&& rm -rf /var/cache/yum \
&& rm -rf /var/cache/dnf 


RUN sed -i "s/#PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config && \
    sed -i 's/#Port.*$/Port 2022/' /etc/ssh/sshd_config && \
    sed -i 's/#MaxSessions 10/MaxSessions 50/' /etc/ssh/sshd_config && \
    sed -i 's/#MaxStartups 10:30:100/MaxStartups 50:30:250/' /etc/ssh/sshd_config && \
    chmod 775 /var/run && \
    chmod 775 /etc/ssh && \
    chmod 660 /etc/ssh/sshd_config && \
    chmod 664 /etc/passwd /etc/group && \
    adduser --system -s /bin/bash -u 1001 -g 0 mpi && \
    chmod 775 /home && \
    mkdir -p /.ipython && \
    chmod 775 /.ipython && \
    cat /etc/passwd

COPY scripts/entrypoint.sh /entrypoint.sh
COPY scripts/configure-mpi-cluster.sh /configure-mpi-cluster.sh

RUN chmod 750 /entrypoint.sh 
COPY etc/environment /etc/environment

USER mpi
COPY --chown=mpi:root notebooks/ /notebooks/
EXPOSE 2022 8888

ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib64/openmpi/bin/"
ENV LD_LIBRARY_PATH="/usr/lib64/openmpi"
ENV PYTHONPATH="/usr/lib64/python3.7/site-packages/openmpi"

CMD [ "/entrypoint.sh"]
