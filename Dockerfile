FROM mythical.alpenland.local:8102/fabian/docker-qtcreator

USER root
COPY ./sources.list /etc/apt/sources.list
RUN apt-get -y update
RUN apt-get -y upgrade

RUN apt-get -y install build-essential
RUN apt-get -y install cmake cmake-qt-gui
RUN apt-get -y install libboost-atomic-dev libboost-chrono-dev libboost-date-time-dev libboost-filesystem-dev libboost-locale-dev libboost-regex-dev libboost-system-dev libboost-thread-dev libboost-program-options-dev
RUN apt-get -y install python2.7-dev python-numpy python-scipy
RUN apt-get -y install libpng-dev libjpeg-dev libtiff-dev zlib1g-dev libglew-dev
RUN apt-get -y install libxml2-dev libcgal-dev libblas-dev liblapack-dev libsuitesparse-dev libassimp-dev

# Other useful tools
RUN apt-get -y install tmux wget zip git vim

USER user
WORKDIR /home/user

CMD ["qtcreator"]
