#!/bin/bash

if [ -f .env ];
then
  . .env
fi

docker build --build-arg UID"=$(id -u)" --build-arg GID="$(id -g)" -t "${DOCKER_IMAGE:-joomlaprojects/docker-images:updater}" -f Dockerfile .
