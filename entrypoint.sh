#!/bin/bash
## ensure all set docker env vars (that begin with EXPORT_) are written to disk in the proper place

rm -f /etc/profile.d/docker-env.sh
touch /etc/profile.d/docker-env.sh

IFS=$'\n'
for LINE in $(env); do
  OIFS=$IFS
  IFS="="
  arr=($LINE)
  if [[ ${arr[0]} == EXPORT_* ]]; then
    VARNAME=$(echo ${arr[0]} | sed 's/EXPORT_//g')
    echo "export $VARNAME=${arr[1]}" >> /etc/profile.d/docker-env.sh
  fi
  IFS=$OIFS
done

chmod +x /etc/profile.d/docker-env.sh
## and finally start whatever services are defined
exec /usr/sbin/runsvdir-start
