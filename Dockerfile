FROM ubuntu:16.04
MAINTAINER John Axel Eriksson <john@insane.se>

ENV \
  USER=john \
  RBENV_MRIS="2.3.1 2.2.5 2.1.10" \
  DEFAULT_MRI=2.1.10 \
  TIMEZONE="Europe/Stockholm" \
  EMAIL=john@insane.se \
  NAME="John Axel Eriksson" \
  USER_UID=1337 \
  USER_GID=1337 \
  GOLANG_VERSION=1.6.2

RUN echo 'deb http://archive.ubuntu.com/ubuntu/ xenial main' | tee /etc/apt/sources.list &&\
    echo 'deb-src http://archive.ubuntu.com/ubuntu/ xenial main' | tee -a /etc/apt/sources.list &&\
    echo 'deb http://archive.ubuntu.com/ubuntu/ xenial-updates main' | tee -a /etc/apt/sources.list &&\
    echo 'deb-src http://archive.ubuntu.com/ubuntu/ xenial-updates main' | tee -a /etc/apt/sources.list &&\
    echo 'deb http://archive.ubuntu.com/ubuntu/ xenial universe' | tee -a /etc/apt/sources.list &&\
    echo 'deb-src http://archive.ubuntu.com/ubuntu/ xenial universe' | tee -a /etc/apt/sources.list &&\
    echo 'deb http://archive.ubuntu.com/ubuntu/ xenial-updates universe' | tee -a /etc/apt/sources.list &&\
    echo 'deb-src http://archive.ubuntu.com/ubuntu/ xenial-updates universe' | tee -a /etc/apt/sources.list &&\
    echo 'deb http://archive.ubuntu.com/ubuntu/ xenial multiverse' | tee -a /etc/apt/sources.list &&\
    echo 'deb-src http://archive.ubuntu.com/ubuntu/ xenial multiverse' | tee -a /etc/apt/sources.list &&\
    echo 'deb http://archive.ubuntu.com/ubuntu/ xenial-updates multiverse' | tee -a /etc/apt/sources.list &&\
    echo 'deb-src http://archive.ubuntu.com/ubuntu/ xenial-updates multiverse' | tee -a /etc/apt/sources.list &&\
    echo 'deb http://archive.ubuntu.com/ubuntu/ xenial-backports main restricted universe multiverse' | tee -a /etc/apt/sources.list &&\
    echo 'deb-src http://archive.ubuntu.com/ubuntu/ xenial-backports main restricted universe multiverse' | tee -a /etc/apt/sources.list &&\
    echo 'deb http://security.ubuntu.com/ubuntu xenial-security main' | tee -a /etc/apt/sources.list &&\
    echo 'deb-src http://security.ubuntu.com/ubuntu xenial-security main' | tee -a /etc/apt/sources.list &&\
    echo 'deb http://security.ubuntu.com/ubuntu xenial-security universe' | tee -a /etc/apt/sources.list &&\
    echo 'deb-src http://security.ubuntu.com/ubuntu xenial-security universe' | tee -a /etc/apt/sources.list &&\
    echo 'deb http://security.ubuntu.com/ubuntu xenial-security multiverse' | tee -a /etc/apt/sources.list &&\
    echo 'deb-src http://security.ubuntu.com/ubuntu xenial-security multiverse' | tee -a /etc/apt/sources.list

# Configure timezone and locale
RUN ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata && \
    sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    sed -i -e 's/# en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen && \
    sed -i -e 's/# sv_SE.UTF-8 UTF-8/sv_SE.UTF-8 UTF-8/' /etc/locale.gen && \
    echo 'LANG="en_US.UTF-8"' > /etc/default/locale && \
    dpkg-reconfigure -f noninteractive locales && \
    update-locale LANG=en_US.UTF-8 &&\
    apt-get update &&\
    apt-get upgrade -y -q &&\
    apt-get dist-upgrade -y -q &&\
    DEBIAN_FRONTEND=noninteractive apt-get install --force-yes -y -q adduser xz-utils nodejs npm whois runit phantomjs vim-nox \
    zsh tmux ssh openssh-server aptitude silversearcher-ag expect mosh git-flow dnsutils tree parallel python3 python3-pip libjson-perl \
    postgresql-client-9.5 xclip libgtkmm-3.0-1v5 libcurl4-openssl-dev libffi-dev libmagick++-dev imagemagick libmagickcore-dev \
    libmagickcore-extra libmagickwand-dev mercurial mongodb-clients apache2-utils valgrind build-essential cmake devscripts curl \
    sudo net-tools git software-properties-common python-software-properties libssl-dev wget ssl-cert bison openssl libreadline6 \
    libreadline6-dev zlib1g zlib1g-dev libsqlite3-0 libsqlite3-dev sqlite3 libxml2-dev libxslt-dev libxml2-utils libreadline6 \
    libreadline6-dev libpq-dev libreadline-dev libncurses5-dev libncursesw5-dev netcat-openbsd traceroute secure-delete inetutils-ping \
    dialog automake help2man siege jq entr direnv &&\
## node is installed as nodejs, link it
    ln -s /usr/bin/nodejs /usr/bin/node &&\
## imagemagick is stupid
    ln -s /usr/lib/x86_64-linux-gnu/ImageMagick-*/bin-Q16/Magick-config /usr/bin/Magick-config &&\
## neovim
    add-apt-repository ppa:neovim-ppa/unstable -y &&\
    apt-get update &&\
    pip3 install powerline-status &&\
    DEBIAN_FRONTEND=noninteractive apt-get install --force-yes -y -q neovim &&\
    pip3 install --user neovim &&\
## disable ssh password auth
    sed -ri "s/#PasswordAuthentication yes/PasswordAuthentication no/g" /etc/ssh/sshd_config &&\
    sed -ri "s/PasswordAuthentication yes/PasswordAuthentication no/g" /etc/ssh/sshd_config &&\
    apt-get clean &&\
    apt-get -y -q autoclean &&\
    apt-get -y -q autoremove &&\
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD bootstrap.sh /root/bootstrap.sh
RUN chmod +x /root/bootstrap.sh &&\
    /root/bootstrap.sh &&\
    rm /root/bootstrap.sh &&\
    apt-get clean &&\
    apt-get -y -q autoclean &&\
    apt-get -y -q autoremove &&\
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

VOLUME ["/home/john"]

EXPOSE 22
CMD ["/entrypoint.sh"]
