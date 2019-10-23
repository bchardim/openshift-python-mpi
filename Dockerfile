# vi: ft=Dockerfile
FROM registry.fedoraproject.org/fedora-minimal:30


RUN microdnf install -y \
python3 \
python3-notebook \
python3-ipython \
python3-openmpi* \
python3-mpi4py* \
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
openssh \
openssh-server \
openssh-clients \
openssl-libs \
&& dnf reinstall -y tzdata \ 
&& microdnf update \
&& microdnf clean all \
&& rm -rf /var/cache/yum \
&& rm -rf /var/cache/dnf 


RUN sed -i "s/#PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config && \
    sed -i 's/#Port.*$/Port 2022/' /etc/ssh/sshd_config && \
    chmod 775 /var/run && \
    chmod 775 /etc/ssh && \
    chmod 660 /etc/ssh/sshd_config && \
    chmod 664 /etc/passwd /etc/group && \
    adduser --system -s /bin/bash -u 10001 -g 0 sds && \
    chmod 775 /home && \
    cat /etc/passwd

COPY scripts/entrypoint.sh  /entrypoint.sh

RUN chmod 750 /entrypoint.sh 
COPY etc/profile.d/ /etc/profile.d/
COPY etc/environment /etc/environment

USER sds
COPY --chown=sds:root src/ src/
EXPOSE 2022
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib64/openmpi/bin/"
ENV LD_LIBRARY_PATH="/usr/lib64/openmpi"
ENV PYTHONPATH="/usr/lib64/python2.7/site-packages/openmpi"

CMD [ "/entrypoint.sh"]
