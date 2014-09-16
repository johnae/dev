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

mkdir -p rsa_keys

openssl rsa -in id_rsa  -out rsa_keys/id_rsa_plain_text
## so ssh-keygen doesn't complain
chmod 0600 rsa_keys/id_rsa_plain_text
ssh-keygen -y -f rsa_keys/id_rsa_plain_text > rsa_keys/id_rsa.pub
chmod 0644 rsa_keys/id_rsa_plain_text
cp id_rsa rsa_keys/id_rsa

for RSAKEY in $(ls id_rsa_*); do
cp $RSAKEY rsa_keys/$RSAKEY
done

cp authorized_keys rsa_keys/authorized_keys

docker build -t johnae/dev --no-cache .

rm -rf rsa_keys
