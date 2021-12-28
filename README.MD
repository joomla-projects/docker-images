# Docker Images for Joomla CI

This repo contains several images for Joomla development.

# Build Image

```sh
docker build --no-cache --build-arg COMPOSERSIG=$(curl https://composer.github.io/installer.sig) --pull -t joomlaprojects/docker-images:php8.1-test .
```
