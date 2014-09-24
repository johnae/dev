FROM quay.io/trice/app-tricefy-3:latest
MAINTAINER John Axel Eriksson <john@insane.se>

ENV USER john

# for git
ENV EMAIL john@insane.se
ENV NAME John Axel Eriksson
ENV USER_UID 1337
ENV USER_GID 1337

ENV GOLANG_VERSION 1.3.1
ENV ELIXIR_VERSION 1.0.0
ENV S3GOF3R_VERSION 0.4.3

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
