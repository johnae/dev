#!/bin/bash

EXIT_NOW=0
if [ ! -e id_rsa ]; then
  echo "You must add your ENCRYPTED id_rsa key to this directory (named id_rsa)"
  EXIT_NOW=1
fi
if [ ! -e authorized_keys ]; then
  echo "You must add an authorized_keys files to this directory (named authorized_keys), otherwise you can't login to the container"
  EXIT_NOW=1
fi
if [ $EXIT_NOW -ne 0 ]; then
  exit 1
fi

chmod 0600 id_rsa
openssl rsa -in id_rsa  -out id_rsa_plain_text
chmod 0600 id_rsa_plain_text
ssh-keygen -y -f id_rsa_plain_text > id_rsa.pub

docker build -t johnae/dev --no-cache .

rm -f id_rsa_plain_text id_rsa.pub
