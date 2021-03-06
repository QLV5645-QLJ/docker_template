FROM nvidia/cudagl:11.0-devel-ubuntu18.04

# TensorFlow version is tightly coupled to CUDA and cuDNN so it should be selected carefully
ENV DISPLAY=:1 \
    VNC_PORT=5901 \
    NO_VNC_PORT=6901
EXPOSE $VNC_PORT $NO_VNC_PORT

ENV HOME=/root \
    INST=/headless \
    TERM=xterm \
    STARTUPDIR=/dockerstartup \
    INST_SCRIPTS=/headless/install \
    NO_VNC_HOME=/headless/noVNC \
    DEBIAN_FRONTEND=noninteractive \
    VNC_COL_DEPTH=24 \
    VNC_RESOLUTION=1920x1080 \
    VNC_PW=vncpassword \
    VNC_VIEW_ONLY=false \
    LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'
WORKDIR $HOME

ENV NCCL_VERSION=2.4.7-1+cuda10.0

COPY ./src/common/install/ $INST_SCRIPTS/
COPY ./src/ubuntu/install/ $INST_SCRIPTS/
COPY ./src/common/xfce/ $INST/
COPY ./src/common/scripts $STARTUPDIR
COPY ./src/ubuntu/repo/sshd_config /etc/ssh/
ADD ./src/homeinit/ $INST/

RUN apt-get update && apt-get install -y --no-install-recommends apt-utils
RUN apt-get update -y \
        && apt-get install -y --allow-downgrades --allow-change-held-packages --no-install-recommends \
        build-essential \
        cmake \
        git \
        curl \
        vim \
        wget \
        ca-certificates \
        libnccl2=${NCCL_VERSION} \
        libnccl-dev=${NCCL_VERSION} \
        libjpeg-dev \
        libpng-dev \
        libnuma-dev \
        libtool \
        libglfw3-dev libglm-dev libx11-dev libomp-dev \
        libegl1-mesa-dev pkg-config \
        net-tools \
        iproute2 \
        iputils-ping \
        eog \
        unzip zip\
        tk-dev python-tk \
        openssh-server \
        ssh-askpass \
        software-properties-common \
        python python-dev python-setuptools \
        python3 python3-dev python3-setuptools \
        coinor-libcoinutils-dev  coinor-libclp-dev \
        coinor-libcbc-dev python-pip gnome-terminal \
        && apt clean -y \
        && apt autoremove -y \
        && rm -rf /var/lib/apt/lists/*

# Install related tools
RUN wget https://github.com/Kitware/CMake/releases/download/v3.13.4/cmake-3.13.4-Linux-x86_64.sh\
    && mkdir /opt/cmake \
    && sh cmake-3.13.4-Linux-x86_64.sh --prefix=/opt/cmake --skip-license \
    && ln -s /opt/cmake/bin/cmake /usr/local/bin/cmake \
    && cmake --version
RUN find $INST_SCRIPTS -name '*.sh' -exec chmod a+x {} + \
    && $INST_SCRIPTS/tools.sh \
    && $INST_SCRIPTS/install_custom_fonts.sh \
    && $INST_SCRIPTS/tigervnc.sh \
    && $INST_SCRIPTS/no_vnc.sh  \
    && $INST_SCRIPTS/firefox.sh  \
    && $INST_SCRIPTS/chrome.sh  \
    && $INST_SCRIPTS/vscode.sh  \
    && $INST_SCRIPTS/xfce_ui.sh \
    && apt install -y sudo git \
    && $INST_SCRIPTS/libnss_wrapper.sh \
    && $INST_SCRIPTS/set_user_permission.sh $STARTUPDIR $HOME $INST \
    && apt clean -y \
    && apt autoremove -y
RUN apt install -y sshpass libtool libtool-bin


#install ros, ros2 and webots
COPY ./src/ros/install_ros.sh /$HOME/installation_dep/
RUN sh /$HOME/installation_dep/install_ros.sh
COPY ./src/ros/install_webots.sh /$HOME/installation_dep/
RUN sh /$HOME/installation_dep/install_webots.sh
COPY ./src/ros/install_ros2.sh /$HOME/installation_dep/
RUN sh /$HOME/installation_dep/install_ros2.sh

#===================important=================
COPY ./src/common/start_scripts/ $STARTUPDIR/
COPY ./src/common/bin/ /usr/local/bin/
COPY ./src/startup/ $STARTUPDIR/
RUN $INST_SCRIPTS/set_user_permission.sh $STARTUPDIR 

# add users
WORKDIR $HOME
USER 0
ENTRYPOINT ["/dockerstartup/sim_startup.sh"]
CMD ["--wait"]
