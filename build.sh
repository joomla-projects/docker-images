#!/bin/bash

if [ -f .env ];
then
  . .env
fi

docker build -t "${DOCKER_IMAGE:-joomlaprojects/docker-images:latest}" -f Dockerfile .
