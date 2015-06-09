FROM ubuntu:15.04
MAINTAINER John Axel Eriksson <john@insane.se>

ENV \
  USER=john \
  RBENV_MRIS="2.2.2 2.1.6 1.9.3-p551" \
  DEFAULT_MRI=2.1.6 \
  TIMEZONE="Europe/Stockholm" \
  EMAIL=john@insane.se \
  NAME="John Axel Eriksson" \
  USER_UID=1337 \
  USER_GID=1337 \
  GOLANG_VERSION=1.4.2 \
  S3GOF3R_VERSION=0.4.10

RUN echo 'deb http://archive.ubuntu.com/ubuntu/ vivid main' | tee /etc/apt/sources.list &&\
    echo 'deb-src http://archive.ubuntu.com/ubuntu/ vivid main' | tee -a /etc/apt/sources.list &&\
    echo 'deb http://archive.ubuntu.com/ubuntu/ vivid-updates main' | tee -a /etc/apt/sources.list &&\
    echo 'deb-src http://archive.ubuntu.com/ubuntu/ vivid-updates main' | tee -a /etc/apt/sources.list &&\
    echo 'deb http://archive.ubuntu.com/ubuntu/ vivid universe' | tee -a /etc/apt/sources.list &&\
    echo 'deb-src http://archive.ubuntu.com/ubuntu/ vivid universe' | tee -a /etc/apt/sources.list &&\
    echo 'deb http://archive.ubuntu.com/ubuntu/ vivid-updates universe' | tee -a /etc/apt/sources.list &&\
    echo 'deb-src http://archive.ubuntu.com/ubuntu/ vivid-updates universe' | tee -a /etc/apt/sources.list &&\
    echo 'deb http://archive.ubuntu.com/ubuntu/ vivid multiverse' | tee -a /etc/apt/sources.list &&\
    echo 'deb-src http://archive.ubuntu.com/ubuntu/ vivid multiverse' | tee -a /etc/apt/sources.list &&\
    echo 'deb http://archive.ubuntu.com/ubuntu/ vivid-updates multiverse' | tee -a /etc/apt/sources.list &&\
    echo 'deb-src http://archive.ubuntu.com/ubuntu/ vivid-updates multiverse' | tee -a /etc/apt/sources.list &&\
    echo 'deb http://archive.ubuntu.com/ubuntu/ vivid-backports main restricted universe multiverse' | tee -a /etc/apt/sources.list &&\
    echo 'deb-src http://archive.ubuntu.com/ubuntu/ vivid-backports main restricted universe multiverse' | tee -a /etc/apt/sources.list &&\
    echo 'deb http://security.ubuntu.com/ubuntu vivid-security main' | tee -a /etc/apt/sources.list &&\
    echo 'deb-src http://security.ubuntu.com/ubuntu vivid-security main' | tee -a /etc/apt/sources.list &&\
    echo 'deb http://security.ubuntu.com/ubuntu vivid-security universe' | tee -a /etc/apt/sources.list &&\
    echo 'deb-src http://security.ubuntu.com/ubuntu vivid-security universe' | tee -a /etc/apt/sources.list &&\
    echo 'deb http://security.ubuntu.com/ubuntu vivid-security multiverse' | tee -a /etc/apt/sources.list &&\
    echo 'deb-src http://security.ubuntu.com/ubuntu vivid-security multiverse' | tee -a /etc/apt/sources.list

RUN locale-gen en_US en_US.UTF-8 &&\
    dpkg-reconfigure locales &&\
    ln -sf /usr/share/zoneinfo/UTC /etc/localtime &&\
    apt-get update &&\
    apt-get upgrade -y -q &&\
    apt-get dist-upgrade -y -q &&\
    DEBIAN_FRONTEND=noninteractive apt-get install --force-yes -y -q adduser xz-utils nodejs npm whois runit phantomjs vim-nox zsh tmux ssh openssh-server aptitude silversearcher-ag expect mosh git-flow dnsutils tree parallel python3 python3-pip mutt mutt-patched task libjson-perl postgresql-client-9.4 redis-tools irssi xclip libgtkmm-3.0-1 libcurl4-openssl-dev libffi-dev imagemagick libmagickcore-dev libmagickcore-extra libmagickwand-dev mercurial mongodb-clients apache2-utils valgrind build-essential cmake devscripts curl sudo net-tools git software-properties-common python-software-properties libssl-dev wget ssl-cert bison openssl libreadline6 libreadline6-dev zlib1g zlib1g-dev libsqlite3-0 libsqlite3-dev sqlite3 libxml2-dev libxslt-dev libxml2-utils libreadline6 libreadline6-dev libpq-dev libreadline-dev libncurses5-dev libncursesw5-dev netcat-openbsd traceroute secure-delete inetutils-ping dialog &&\
## node is installed as nodejs, link it
    ln -s /usr/bin/nodejs /usr/bin/node &&\
    apt-get clean &&\
    apt-get -y -q autoclean &&\
    apt-get -y -q autoremove &&\
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* &&\
    ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime

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
