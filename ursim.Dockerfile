FROM ubuntu:16.04

ARG URSIM_USER
ARG URSIM_GROUP
ARG URSIM_USER_UID
ARG URSIM_USER_GID
ARG URSIM_TAR_ARCHIVE
ARG URSIM_DIRECTORY

#   Set enviroment to build from bitbucket
ENV HOME /home/${URSIM_USER}

USER root

RUN groupdel  ${URSIM_GROUP} || true
RUN groupadd -g ${URSIM_USER_GID} ${URSIM_GROUP} || true

RUN userdel ${URSIM_USER} || true
RUN /bin/bash -c "useradd -s /bin/bash ${URSIM_USER} || true && \
		  usermod -a -G ${URSIM_GROUP} ${URSIM_USER}"

RUN /bin/bash -c "mkdir -p ${HOME} && mkdir -p ${HOME}/Desktop && chown -R ${URSIM_USER}.${URSIM_USER} ${HOME}"

# Install prerequisites
RUN apt-get update && apt-get install -y apt-transport-https systemd
COPY sources.list /etc/apt/sources.list

RUN apt-get -y update && apt-get -y upgrade && apt-get clean && \
	apt-get -y install apt-utils lsb-release curl git cron at logrotate rsyslog \
		unattended-upgrades ssmtp lsof procps \
		initscripts libsystemd0 libudev1 systemd sysvinit-utils udev util-linux && \
	apt-get clean && \
	sed -i '/imklog/{s/^/#/}' /etc/rsyslog.conf

RUN apt-get install -y --allow-unauthenticated sudo \
    autoconf automake \
    ssh net-tools \
    curl libcurl3 php-curl \
    software-properties-common python-software-properties \
    pkg-config \
    policykit-1 \
    vim \
    xterm \
    default-jdk-headless \
    iputils-ping
    
# unattended upgrades & co
ADD apt_unattended-upgrades /etc/apt/apt.conf.d/50unattended-upgrades
ADD apt_periodic /etc/apt/apt.conf.d/02periodic

RUN cd /lib/systemd/system/sysinit.target.wants/ && \
		ls | grep -v systemd-tmpfiles-setup.service | xargs rm -f && \
		rm -f /lib/systemd/system/sockets.target.wants/*udev* && \
		systemctl mask -- \
			tmp.mount \
			etc-hostname.mount \
			etc-hosts.mount \
			etc-resolv.conf.mount \
			-.mount \
			swap.target \
			getty.target \
			getty-static.service \
			dev-mqueue.mount \
			cgproxy.service \
			systemd-tmpfiles-setup-dev.service \
			systemd-remount-fs.service \
			systemd-ask-password-wall.path \
			systemd-logind.service && \
		systemctl set-default multi-user.target || true
		
RUN sed -ri /etc/systemd/journald.conf \
			-e 's!^#?Storage=.*!Storage=volatile!'
ADD container-boot.service /etc/systemd/system/container-boot.service
RUN mkdir -p /etc/container-boot.d && \
		systemctl enable container-boot.service

USER root
WORKDIR /opt

COPY ./${URSIM_TAR_ARCHIVE} /opt/${URSIM_TAR_ARCHIVE}
RUN tar xvfz /opt/${URSIM_TAR_ARCHIVE}

WORKDIR /opt/${URSIM_DIRECTORY}
COPY ./install.sh /opt/${URSIM_DIRECTORY}/install.sh
RUN /bin/bash -c "chmod +x ./install.sh && ./install.sh"

EXPOSE 30000:30004

# run stuff
ADD configurator.sh configurator_dumpenv.sh /root/
ADD configurator.service configurator_dumpenv.service /etc/systemd/system/
RUN chmod 700 /root/configurator.sh /root/configurator_dumpenv.sh && \
		systemctl enable configurator.service configurator_dumpenv.service

COPY ./docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN /bin/bash -c "chmod +x /usr/local/bin/docker-entrypoint.sh"

VOLUME [ "/sys/fs/cgroup", "/run", "/run/lock", "/tmp" ]
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
# CMD ["/lib/systemd/systemd"]
CMD ["/bin/bash", "-c", "/opt/ursim-3.6.0.30512/start-ursim.sh", "UR10"]
