#!/bin/bash

defined () {
    [[ ${!1-X} == ${!1-Y} ]]
}

has_value () {
    if defined $1; then
        if [[ -n ${!1} ]]; then
            return 0
        fi
    fi
    return 1
}

EXIT_NOW=0
if [ ! -e id_rsa ]; then
  echo "You must add your id_rsa key to this directory (named id_rsa)"
  EXIT_NOW=1
fi
if [ ! -e authorized_keys ]; then
  echo "You must add an authorized_keys files to this directory (named authorized_keys), otherwise you can't login to the container"
  EXIT_NOW=1
fi

if ! has_value TMP_BUCKET; then
  echo "you must set the env var TMP_BUCKET"
  EXIT_NOW=1
fi

if ! has_value AWS_ACCESS_KEY_ID; then
  echo "you must set the env var AWS_ACCESS_KEY_ID"
  EXIT_NOW=1
fi

if ! has_value AWS_SECRET_ACCESS_KEY; then
  echo "you must set the env var AWS_SECRET_ACCESS_KEY"
  EXIT_NOW=1
fi

if ! has_value AWS_REGION; then
  echo "you must set the env var AWS_REGION"
  EXIT_NOW=1
fi

if ! has_value SSH_KEY_PASS; then
  echo "you must set the env var SSH_KEY_PASS"
  EXIT_NOW=1
fi

if [ $EXIT_NOW -ne 0 ]; then
  exit 1
fi

rm -rf plain_rsa_keys* encrypted_rsa_keys*

mkdir -p plain_rsa_keys
mkdir -p encrypted_rsa_keys

openssl rsa -in id_rsa -passin "pass:$SSH_KEY_PASS" -out plain_rsa_keys/id_rsa
## so ssh-keygen doesn't complain
chmod 0600 plain_rsa_keys/id_rsa
ssh-keygen -y -f plain_rsa_keys/id_rsa > plain_rsa_keys/id_rsa.pub
cp plain_rsa_keys/id_rsa.pub encrypted_rsa_keys/id_rsa.pub
chmod 0644 plain_rsa_keys/id_rsa

for RSAKEY in $(ls id_rsa*); do
  openssl pkcs8 -topk8 -v2 des3 -in $RSAKEY -passin "pass:$SSH_KEY_PASS" -out encrypted_rsa_keys/$(basename $RSAKEY) -passout "pass:$SSH_KEY_PASS"
done

cp authorized_keys plain_rsa_keys/authorized_keys
cp authorized_keys encrypted_rsa_keys/authorized_keys

BUCKET_PSEUDO_DIR=$(openssl rand -hex 32)

tar czf - plain_rsa_keys | ./gof3r put --bucket $TMP_BUCKET --header --endpoint s3-$AWS_REGION.amazonaws.com -m x-amz-server-side-encryption:AES256 -k $BUCKET_PSEUDO_DIR/plain_rsa_keys.tar.gz
tar czf - encrypted_rsa_keys | ./gof3r put --bucket $TMP_BUCKET --header --endpoint s3-$AWS_REGION.amazonaws.com -m x-amz-server-side-encryption:AES256 -k $BUCKET_PSEUDO_DIR/encrypted_rsa_keys.tar.gz

cat bootstrap.sh.tmpl | sed "s/TMPL_DOCKER_TMP_BUCKET/$TMP_BUCKET/g" | sed "s/TMPL_REGION/s3-$AWS_REGION/g" | sed "s/TMPL_PSEUDO_BUCKET_DIR/$BUCKET_PSEUDO_DIR/g" > bootstrap.sh
chmod +x bootstrap.sh

rm -rf plain_rsa_keys* encrypted_rsa_keys*

docker build --force-rm -t johnae/dev .
rm bootstrap.sh
