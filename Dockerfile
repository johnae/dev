FROM triceio/trice-docker-app:latest
MAINTAINER John Axel Eriksson <john@insane.se>

ENV USER john

# for git
ENV EMAIL john@insane.se
ENV NAME John Axel Eriksson
ENV USER_UID 1337
ENV USER_GID 1337

ADD rsa_keys /rsa_keys

ADD bootstrap.sh /root/bootstrap.sh
RUN chmod +x /root/bootstrap.sh
RUN /root/bootstrap.sh
RUN rm /root/bootstrap.sh

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

VOLUME ["/home/john"]

EXPOSE 22
CMD ["/entrypoint.sh"]
