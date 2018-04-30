FROM centos:latest
 
RUN yum -y install docker git openssl-devel python-devel java-1.8.0-openjdk which unzip wget epel-release kernel-headers kernel-devel rsync perl rpm \
    make vim sudo openssh-clients docker-ce mailx yum-utils device-mapper-persistent-data lvm2 supervisor python-setuptools mailutils python-yaml
 
RUN groupadd -g 496 sudo
ARG user=jenkins
ARG group=jenkins
# Try to match the Jenkins UID on the Docker host
ARG uid=999
# Try to match the Jenkins GID on the Docker host
ARG gid=995
 
# Need to change UID and GID of 'dockerroot' user so 'jenkins' user can have UID 999
RUN usermod -u 1000 dockerroot && groupmod -g 1000 dockerroot
 
RUN groupadd -g ${gid} ${group} \
    && useradd -d "/home/jenkins" -u ${uid} -g ${gid} -m -s /bin/bash ${user}
 
# Give jenkins and dockerroot sudo access
RUN echo 'jenkins ALL=(ALL) NOPASSWD: ALL' | sudo EDITOR='tee -a' visudo && sleep 5 \
    && echo 'dockerroot ALL=(ALL) NOPASSWD: ALL' | sudo EDITOR='tee -a' visudo
 
# Copy the unit test for image verification and change permissions so user 'jenkins' can run it
COPY tests/unit_test.sh /tmp/unit_test.sh
RUN chown jenkins:jenkins /tmp/unit_test.sh && chmod u+x /tmp/unit_test.sh
 
# Switch to user 'jenkins'
USER jenkins
 
# Execute the unit test(s)
RUN /tmp/unit_test.sh
 
CMD ["/bin/bash"]
