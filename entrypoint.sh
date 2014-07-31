#!/bin/bash
## ensure all set docker env vars (that begin with DOCKER_) are written to disk in the proper place

rm -f /etc/profile.d/docker-env.sh
touch /etc/profile.d/docker-env.sh

IFS=$'\n'
for LINE in $(env); do
  OIFS=$IFS
  IFS="="
  arr=($LINE)
  if [[ ${arr[0]} == DOCKER_* ]]; then
    echo "export ${arr[0]}=${arr[1]}" >> /etc/profile.d/docker-env.sh
  fi
  IFS=$OIFS
done

chmod +x /etc/profile.d/docker-env.sh

## and finally start whatever services are defined
/usr/sbin/runsvdir-start
