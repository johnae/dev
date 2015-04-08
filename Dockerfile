FROM ubuntu:14.04
MAINTAINER John Axel Eriksson <john@insane.se>

ENV USER john
ENV RBENV_MRIS 2.2.1 2.1.5 1.9.3-p551
ENV DEFAULT_MRI 2.1.5
#ENV RBENV_JRUBY jruby-1.7.19

# for git
ENV EMAIL john@insane.se
ENV NAME John Axel Eriksson
ENV USER_UID 1337
ENV USER_GID 1337

ENV GOLANG_VERSION 1.4.2
#ENV ELIXIR_VERSION 1.0.0 ## not used anymore
ENV S3GOF3R_VERSION 0.4.9

RUN echo 'deb http://archive.ubuntu.com/ubuntu/ trusty main' | tee /etc/apt/sources.list &&\
    echo 'deb-src http://archive.ubuntu.com/ubuntu/ trusty main' | tee -a /etc/apt/sources.list &&\
    echo 'deb http://archive.ubuntu.com/ubuntu/ trusty-updates main' | tee -a /etc/apt/sources.list &&\
    echo 'deb-src http://archive.ubuntu.com/ubuntu/ trusty-updates main' | tee -a /etc/apt/sources.list &&\
    echo 'deb http://archive.ubuntu.com/ubuntu/ trusty universe' | tee -a /etc/apt/sources.list &&\
    echo 'deb-src http://archive.ubuntu.com/ubuntu/ trusty universe' | tee -a /etc/apt/sources.list &&\
    echo 'deb http://archive.ubuntu.com/ubuntu/ trusty-updates universe' | tee -a /etc/apt/sources.list &&\
    echo 'deb-src http://archive.ubuntu.com/ubuntu/ trusty-updates universe' | tee -a /etc/apt/sources.list &&\
    echo 'deb http://archive.ubuntu.com/ubuntu/ trusty multiverse' | tee -a /etc/apt/sources.list &&\
    echo 'deb-src http://archive.ubuntu.com/ubuntu/ trusty multiverse' | tee -a /etc/apt/sources.list &&\
    echo 'deb http://archive.ubuntu.com/ubuntu/ trusty-updates multiverse' | tee -a /etc/apt/sources.list &&\
    echo 'deb-src http://archive.ubuntu.com/ubuntu/ trusty-updates multiverse' | tee -a /etc/apt/sources.list &&\
    echo 'deb http://archive.ubuntu.com/ubuntu/ trusty-backports main restricted universe multiverse' | tee -a /etc/apt/sources.list &&\
    echo 'deb-src http://archive.ubuntu.com/ubuntu/ trusty-backports main restricted universe multiverse' | tee -a /etc/apt/sources.list &&\
    echo 'deb http://security.ubuntu.com/ubuntu trusty-security main' | tee -a /etc/apt/sources.list &&\
    echo 'deb-src http://security.ubuntu.com/ubuntu trusty-security main' | tee -a /etc/apt/sources.list &&\
    echo 'deb http://security.ubuntu.com/ubuntu trusty-security universe' | tee -a /etc/apt/sources.list &&\
    echo 'deb-src http://security.ubuntu.com/ubuntu trusty-security universe' | tee -a /etc/apt/sources.list &&\
    echo 'deb http://security.ubuntu.com/ubuntu trusty-security multiverse' | tee -a /etc/apt/sources.list &&\
    echo 'deb-src http://security.ubuntu.com/ubuntu trusty-security multiverse' | tee -a /etc/apt/sources.list

RUN locale-gen en_US en_US.UTF-8 &&\
    dpkg-reconfigure locales &&\
    ln -sf /usr/share/zoneinfo/UTC /etc/localtime &&\
    apt-get update &&\
    apt-get upgrade -y -q &&\
    apt-get dist-upgrade -y -q &&\
    apt-get install --force-yes -y -q build-essential devscripts curl sudo net-tools git software-properties-common python-software-properties libssl-dev wget ssl-cert bison openssl libreadline6 libreadline6-dev zlib1g zlib1g-dev libsqlite3-0 libsqlite3-dev sqlite3 libxml2-dev libxslt-dev libreadline6 libreadline6-dev libpq-dev cron logrotate &&\
    apt-get clean &&\
    apt-get -y -q autoclean &&\
    apt-get -y -q autoremove &&\
    rm -rf /tmp/*

ADD bootstrap.sh /root/bootstrap.sh
RUN chmod +x /root/bootstrap.sh &&\
    /root/bootstrap.sh &&\
    rm /root/bootstrap.sh &&\
    apt-get -y -q autoclean &&\
    apt-get -y -q autoremove &&\
    rm -rf /tmp/*

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

VOLUME ["/home/john"]

EXPOSE 22
CMD ["/entrypoint.sh"]
