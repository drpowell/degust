#!/bin/sh

export SECRET_KEY_BASE=secret-key

export GOOGLE_PROVIDER_KEY='keyfromgoogle.apps.googleusercontent.com'
export GOOGLE_PROVIDER_SECRET='secretfromgoogle'

HERE=$(pwd)

docker run --env SECRET_KEY_BASE --env GOOGLE_PROVIDER_KEY --env GOOGLE_PROVIDER_SECRET \
      --volume $HERE/docker-tmp/uploads:/opt/degust/uploads \
      --volume $HERE/docker-tmp/db:/opt/degust/db-file \
      --volume $HERE/docker-tmp/log:/opt/degust/log \
      -p 8001:3000 \
      drpowell/degust
