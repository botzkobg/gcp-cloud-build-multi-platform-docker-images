#!/bin/bash

set -xeuo pipefail

function configureSsh() {
  set +x
  echo "${SSH_PRIVATE_KEY}" > /root/.ssh/id_rsa
  set -x
  chmod 600 /root/.ssh/id_rsa
}

function configureDocker() {
  DEFAULT_DOCKER_CONTEXT=`docker context ls | grep '*' | sed -e 's/ .*//g'`
  docker context create remote-arm-vm --docker "host=ssh://dbuilder@remote-arm-vm"
  docker buildx create --name multi-arch --use remote-arm-vm
  docker buildx create --append --name multi-arch default

  touch ./_docker_is_configured
}

function config() {
  configureSsh
  if [ ! -f "./_docker_is_configured" ]; then
    configureDocker
  fi

  docker context ls
  docker buildx ls

}

config

docker "$@"