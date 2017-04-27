#!/bin/env bash

# Check existence of hub env vars file
#HUB_ENV_FILE=/srv/jupyterhub/env
HUB_ENV_FILE=secret/env #XXX TEMP
if [ -e $HUB_ENV_FILE ]; then
   source $HUB_ENV_FILE
else
   echo "Error: Jupyterhub environment variables file not found in $HUB_ENV_FILE" 1>&2
   exit 1
fi

# Check that we got the vars we want
vars="OAUTH_CLIENT_ID OAUTH_CLIENT_SECRET"
for var in $vars; do
   if [ -z ${!var} ]; then # "indirect parameter expansion"
      echo "Error: Variable $var is not set" 1>&2
      exit 1
   fi
done

# Get the public hostname
#export EC2_PUBLIC_HOSTNAME=`ec2-metadata --public-hostname | sed -ne 's/public-hostname: //p'`
export EC2_PUBLIC_HOSTNAME=localhost #XXX TEMP
if [ -z $EC2_PUBLIC_HOSTNAME ]; then
   echo "Error: Failed to get EC2 public hostname from `ec2-metadata`"
   exit 1
else
   echo "Using EC2_PUBLIC_HOSTNAME=$EC2_PUBLIC_HOSTNAME"
fi
export OAUTH_CALLBACK_URL=https://${EC2_PUBLIC_HOSTNAME}:8443/hub/oauth_callback


# https://jpetazzo.github.io/2015/09/03/do-not-use-docker-in-docker-for-ci/
#docker run -it --rm \
#   -e OAUTH_CLIENT_ID=$OAUTH_CLIENT_ID \
#   -e OAUTH_CLIENT_SECRET=$OAUTH_CLIENT_SECRET \
#   -e OAUTH_CALLBACK_URL=$OAUTH_CALLBACK_URL \
#   -p 8443:8443 \
#   -v /var/run/docker.sock:/var/run/docker.sock \
#   --name "jupyterhub_service" jhubdocker

# https://docs.docker.com/engine/reference/commandline/service_create/#add-bind-mounts-or-volumes
docker service create \
   -e OAUTH_CLIENT_ID=$OAUTH_CLIENT_ID \
   -e OAUTH_CLIENT_SECRET=$OAUTH_CLIENT_SECRET \
   -e OAUTH_CALLBACK_URL=$OAUTH_CALLBACK_URL \
   -p 8443:8443 \
   -p 8444:8444 \
   -p 8888:8888 \
   --mount type=bind,source=/var/run/docker.sock,destination=/var/run/docker.sock \
   --network hubnet \
   --name "jupyterhub_service" jhubdocker