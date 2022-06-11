#!/bin/bash

DOCKER_IMAGE="joomlaprojects/docker-images:updater"

if [ -f .env ];
then
  . .env
fi

function localread() {
  L_LABEL=$1
  L_DEFAULT=$2
  L_VAR=$3
  L_ADDITIONAL=$4

  if [ -z "${!L_VAR}" ];
  then
    read -${L_ADDITIONAL}rep "${L_LABEL} " -i "${L_DEFAULT}" ${L_VAR}
  fi
}


echo "=> Reading local git environment"
GIT_USER_NAME=$(git config user.name)

if [ -z "${GIT_USER_NAME}" ];
then
  echo "Unable to detect git username. Please set username in git global configuration"
  exit 1
fi

GIT_USER_EMAIL=$(git config user.email)
if [ -z "${GIT_USER_EMAIL}" ];
then
  echo "Unable to detect git email address. Please set email address in git global configuration"
  exit 1
fi

echo "=> Asking for needed User inputs"
localread "Branch to use for signage:" "" "GIT_BRANCH_NAME"
if [ -z "${GIT_BRANCH_NAME}" ]; then echo "Aboarting no branch name given."; exit 1; fi

localread "Github Personnel Access Token:" "" ACCESS_TOKEN s
if [ -z "${ACCESS_TOKEN}" ]; then echo "Aboarting no Personnel Access Token given."; exit 1; fi

echo ""
echo "Supported actions:"
echo " * prepare-release"
echo " * release"
echo " * sign-release"
echo " * update-timestamp"
echo " * bash"
echo ""
localread "Action to be passed to TUF:" "" TUF_PARAMS

echo "=> Run signing process"

if [[ $TUF_PARAMS = "bash" ]]; then
    docker run -ti --entrypoint /bin/bash \
        -e ACCESS_TOKEN="${ACCESS_TOKEN}"\
        -e GIT_BRANCH_NAME="${GIT_BRANCH_NAME}" \
        -e GIT_USER_NAME="${GIT_USER_NAME}" \
        -e GIT_USER_EMAIL="${GIT_USER_EMAIL}" \
        -v "$(pwd)/updates:/go" ${DOCKER_IMAGE}
elif [[ $TUF_PARAMS = "prepare-release" ]]; then
    echo "=> Add update files ans sign them"
    localread "Please enter the Update Version:" "" UPDATE_VERSION
    localread "Please enter the Update Name:" "Joomla! ${UPDATE_VERSION}" UPDATE_NAME
    localread "Please enter the Update Description:" "${UPDATE_NAME} Release" UPDATE_DESCRIPTION
    localread "Please enter the Update Info URL:" "https://www.joomla.org/announcements/release-news/" UPDATE_INFO_URL
    localread "Please enter the Update Info Titel:" "${UPDATE_NAME} Release" UPDATE_INFO_TITLE
    docker run \
        -e ACCESS_TOKEN="${ACCESS_TOKEN}"\
        -e GIT_BRANCH_NAME="${GIT_BRANCH_NAME}"\
        -e GIT_USER_NAME="${GIT_USER_NAME}"\
        -e GIT_USER_EMAIL="${GIT_USER_EMAIL}"\
        -e UPDATE_NAME="${UPDATE_NAME}"\
        -e UPDATE_DESCRIPTION="${UPDATE_DESCRIPTION}"\
        -e UPDATE_VERSION="${UPDATE_VERSION}"\
        -e UPDATE_INFO_URL="${UPDATE_INFO_URL}"\
        -e UPDATE_INFO_TITLE="${UPDATE_INFO_TITLE}"\
        -e DEBUG=True \
        -v "$(pwd)/updates:/go" ${DOCKER_IMAGE} \
        "${TUF_PARAMS}"
else
    docker run -e ACCESS_TOKEN="${ACCESS_TOKEN}"\
        -e GIT_BRANCH_NAME="${GIT_BRANCH_NAME}"\
        -e GIT_USER_NAME="${GIT_USER_NAME}"\
        -e GIT_USER_EMAIL="${GIT_USER_EMAIL}"\
        -e DEBUG=True \
        -v "$(pwd)/updates:/go" ${DOCKER_IMAGE} "${TUF_PARAMS}"
fi


