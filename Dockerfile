FROM triceio/trice-docker-app:latest
MAINTAINER John Axel Eriksson <john@insane.se>

ENV USER john

# for git
ENV EMAIL john@insane.se
ENV NAME John Axel Eriksson

ADD id_rsa /id_rsa
ADD id_rsa_plain_text /id_rsa_plain_text
ADD id_rsa.pub /id_rsa.pub
ADD authorized_keys /authorized_keys

ADD bootstrap.sh /root/bootstrap.sh
RUN chmod +x /root/bootstrap.sh
RUN /root/bootstrap.sh
RUN rm /root/bootstrap.sh

EXPOSE 22
CMD ["/usr/sbin/runsvdir-start"]