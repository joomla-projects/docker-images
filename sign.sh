#!/bin/bash

SIGNER_DIR="$(dirname "$(readlink -f "$0")")"

DOCKER_IMAGE="joomlaprojects/docker-images:updater"

GIT_BASE_BRANCH_NAME=main
GIT_TARGET_BRANCH_NAME=${GIT_BASE_BRANCH_NAME}

TUF_TARGETS_PASSPHRASE=""
TUF_TIMESTAMP_PASSPHRASE=""
TUF_SNAPSHOT_PASSPHRASE=""
TUF_ROOT_PASSPHRASE=""

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
    read "-${L_ADDITIONAL}rep" "${L_LABEL} " -i "${L_DEFAULT}" "${L_VAR}"
  fi
}

function userConfirm() {
  read -rp "Confirm (y/N): " USERCONFIRMATION
  if [[ $USERCONFIRMATION = "y" || $USERCONFIRMATION = "Y" ]]; then
    :
    else
      echo '=> Quitting'
      exit 1
  fi
}

function checkReleaseFolder() {
  release_folder_status="$(find ./release/ -iname '*.zip')"
  if [[ $release_folder_status != "" ]]; then
    echo '=> Move file from release to updates/stage/targets'
    for file in ./release**/*.zip; do
      echo $file
      mkdir -p "updates/staged/targets/"
      #mv "$file" updates/staged/targets/
      cp "$file" updates/staged/targets/
    done
  else
    echo '=> Relase Folder has no ZIP files, is this correct?'
    userConfirm
  fi
}

function loadkeys() {
    mkdir -p $SIGNER_DIR/updates/keys
    $($SIGNER_DIR/tools/keys_${KEY_ADAPTER}.sh)
}

function checkkey() {
    if [ ! -f "$SIGNER_DIR/updates/keys/$1.json" ]; then
        echo "Key 'targets' not found."
        cleanupdocker
        exit 1
    fi
}

# if we create new keys we will save them automatically to the private directory
function savekeys() {
    if [ "$(ls -A $SIGNER_DIR/updates/keys)" ]; then
        echo "New keys found."
        NOW=$(date +%Y-%m-%dT%H:%M:%S)
        mkdir -p $SIGNER_DIR/private/$NOW
        cp $SIGNER_DIR/updates/keys/* $SIGNER_DIR/private/$NOW
        echo "Keys have been saved to $SIGNER_DIR/private/$NOW please secure them"
    fi;
}

function cleanupdocker() {
    if [ "$(ls -A $SIGNER_DIR/updates/keys)" ]; then
        echo "Cleaning Keys..."
        rm $SIGNER_DIR/updates/keys/*
    fi;
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

# TODO - Delete
# echo "=> Asking for needed User inputs"
# localread "Branch to use for signage:" "" "GIT_TARGET_BRANCH_NAME"
# if [ -z "${GIT_TARGET_BRANCH_NAME}" ]; then echo "Aborting no branch name given."; exit 1; fi

localread "Github Personnel Access Token:" "" ACCESS_TOKEN s
if [ -z "${ACCESS_TOKEN}" ]; then echo "Aborting no Personnel Access Token given."; exit 1; fi

echo ""
echo "Supported actions"
echo ""
echo "Release Actions:"
echo " 1 prepare-release"
echo " 2 sign-release"
echo " 3 release"
echo ""
echo "Signature Actions:"
echo " 4 create-key"
echo " 5 sign-key"
echo " 6 commit-key"
echo ""
echo "Maintenance Actions:"
echo " 7 update-timestamp"
echo " 8 bash"
echo " 9 clean docker environment"
echo " 10 DEBUG Shell"
echo ""
localread "Action to be passed to TUF:" "" TUF_PARAMS

declare -A TUF_ACTIONS=( [1]=prepare-release [2]=sign-release [3]=release [4]=create-key [5]=sign-key [6]=commit-key [7]=update-timestamp [8]=bash [9]=clean-docker [10]=DEBUG)

for key in "${!TUF_ACTIONS[@]}"; do
  if [ "$key" == "$TUF_PARAMS" ]; then
    TUF_PARAMS=${TUF_ACTIONS[$key]};
  fi
done

# Prepare standard environment parameters for the docker iamge
DOCKER_ENV_FILE=$(mktemp)
echo "ACCESS_TOKEN=${ACCESS_TOKEN}" >> $DOCKER_ENV_FILE
echo "GIT_BASE_BRANCH_NAME=${GIT_BASE_BRANCH_NAME}" >> $DOCKER_ENV_FILE
echo "GIT_TARGET_BRANCH_NAME=${GIT_TARGET_BRANCH_NAME}" >> $DOCKER_ENV_FILE
echo "GIT_USER_NAME=${GIT_USER_NAME}" >> $DOCKER_ENV_FILE
echo "GIT_USER_EMAIL=${GIT_USER_EMAIL}" >> $DOCKER_ENV_FILE
echo "TUF_TARGETS_PASSPHRASE=${TUF_TARGETS_PASSPHRASE}" >> $DOCKER_ENV_FILE
echo "TUF_TIMESTAMP_PASSPHRASE=${TUF_TIMESTAMP_PASSPHRASE}" >> $DOCKER_ENV_FILE
echo "TUF_SNAPSHOT_PASSPHRASE=${TUF_SNAPSHOT_PASSPHRASE}" >> $DOCKER_ENV_FILE
echo "TUF_ROOT_PASSPHRASE=${TUF_ROOT_PASSPHRASE}" >> $DOCKER_ENV_FILE
echo "TUF_PARAMETERS=${TUF_PARAMETERS}" >> $DOCKER_ENV_FILE

echo "=> Run TUF process"

if [[ $TUF_PARAMS = "bash" ]]; then
    loadkeys
    docker run --rm -ti \
        --env-file "$DOCKER_ENV_FILE" \
        -v "$(pwd)/updates:/go" ${DOCKER_IMAGE} \
        "${TUF_PARAMS}"
    cleanupdocker
elif [[ $TUF_PARAMS = "DEBUG" ]]; then
    echo '=> Starting Shell Only for debugging'
    docker run --rm -ti \
        --entrypoint "/bin/bash" \
        --env-file "$DOCKER_ENV_FILE" \
        -v "$(pwd)/updates:/go" ${DOCKER_IMAGE}
elif [[ $TUF_PARAMS = "prepare-release" ]]; then
    checkReleaseFolder
    echo "=> Add update files and sign them"
    localread "Please enter the Update Version:" "" UPDATE_VERSION
    localread "Please enter the Update Name:" "Joomla! ${UPDATE_VERSION}" UPDATE_NAME
    localread "Please enter the Update Description:" "${UPDATE_NAME} Release" UPDATE_DESCRIPTION
    # INFO Url must be asked
    localread "Please enter the Update Info URL:" "https://www.joomla.org/announcements/release-news/" UPDATE_INFO_URL
    localread "Please enter the Update Info Titel:" "${UPDATE_NAME} Release" UPDATE_INFO_TITLE
    sed -i -e "s/GIT_TARGET_BRANCH_NAME=.*/GIT_TARGET_BRANCH_NAME=release\/${GIT_BASE_BRANCH_NAME}\/${UPDATE_VERSION}/g" "$DOCKER_ENV_FILE"
    docker run --rm \
        --env-file "${DOCKER_ENV_FILE}" \
        -e UPDATE_NAME="${UPDATE_NAME}"\
        -e UPDATE_DESCRIPTION="${UPDATE_DESCRIPTION}"\
        -e UPDATE_VERSION="${UPDATE_VERSION}"\
        -e UPDATE_INFO_URL="${UPDATE_INFO_URL}"\
        -e UPDATE_INFO_TITLE="${UPDATE_INFO_TITLE}"\
        -v "$(pwd)/updates:/go" "${DOCKER_IMAGE}" \
        "${TUF_PARAMS}"
elif [[ $TUF_PARAMS = "create-key" || $TUF_PARAMS = "sign-key" || $TUF_PARAMS = "commit-key" ]]; then
    echo "=> Create a signature"
    if [[ $TUF_PARAMS = "create-key" ]]; then
      localread "Please enter the Role (root, targets, snapshot, timestamp):" "" SIGNATURE_ROLE
#      localread "Please enter the Name (Person) the key belongs to:" "" SIGNATURE_ROLE_NAME
    else
      loadkeys
      checkkey "root"
      #localread "Please enter the Role (root, targets, snapshot, timestamp):" "" SIGNATURE_ROLE
      SIGNATURE_ROLE="root"
    fi
    localread "Please enter the Name (Person) the key belongs to:" "" SIGNATURE_ROLE_NAME
    SIGNATURE_BRANCH=`echo ${SIGNATURE_ROLE_NAME} | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g'`

    sed -i -e "s/GIT_TARGET_BRANCH_NAME=.*/GIT_TARGET_BRANCH_NAME=key\/${GIT_BASE_BRANCH_NAME}\/${SIGNATURE_BRANCH}/g" "$DOCKER_ENV_FILE"
    docker run --rm -ti \
        --env-file "$DOCKER_ENV_FILE" \
        -e SIGNATURE_ROLE="${SIGNATURE_ROLE}"\
        -e SIGNATURE_ROLE_NAME="${SIGNATURE_ROLE_NAME}"\
        -v "$(pwd)/updates:/go" ${DOCKER_IMAGE} \
        "${TUF_PARAMS}"
    if [[ $TUF_PARAMS = "create-key" ]]; then
      savekeys
    else
      cleanupdocker
    fi
elif [[ $TUF_PARAMS = "sign-release" ]]; then
  localread "Please enter which Version you would like to sign:" "" UPDATE_VERSION
  sed -i -e "s/GIT_TARGET_BRANCH_NAME=.*/GIT_TARGET_BRANCH_NAME=release\/${GIT_BASE_BRANCH_NAME}\/${UPDATE_VERSION}/g" "$DOCKER_ENV_FILE"
  loadkeys
  checkkey "targets"
  docker run --rm \
    --env-file "$DOCKER_ENV_FILE" \
    -v "$(pwd)/updates:/go" ${DOCKER_IMAGE} "${TUF_PARAMS}"
  cleanupdocker
elif [[ $TUF_PARAMS = "release" ]]; then
  localread "Please enter which Version you would like to release:" "" UPDATE_VERSION
  sed -i -e "s/GIT_TARGET_BRANCH_NAME=.*/GIT_TARGET_BRANCH_NAME=release\/${GIT_BASE_BRANCH_NAME}\/${UPDATE_VERSION}/g" "$DOCKER_ENV_FILE"
  loadkeys
  checkkey "snapshot"
  docker run --rm \
    --env-file "$DOCKER_ENV_FILE" \
    -v "$(pwd)/updates:/go" ${DOCKER_IMAGE} "${TUF_PARAMS}"
  cleanupdocker
elif [[ $TUF_PARAMS = "update-timestamp" ]]; then
  loadkeys
  checkkey "timestamp"
  docker run --rm \
    --env-file "$DOCKER_ENV_FILE" \
    -v "$(pwd)/updates:/go" ${DOCKER_IMAGE} "${TUF_PARAMS}"
  cleanupdocker
elif [[ $TUF_PARAMS = "clean-docker" ]]; then
  if [ ! -d "$SIGNER_DIR/updates/.git" ]; then
    echo "Error $SIGNER_DIR/updates/.git doesn't exists."
    exit 1
  fi
  rm -rf "$SIGNER_DIR/updates"
  mkdir "$SIGNER_DIR/updates"
  docker run --rm \
    --env-file "$DOCKER_ENV_FILE" \
    -v "$(pwd)/updates:/go" ${DOCKER_IMAGE} "bash"
else
    docker run --rm \
        --env-file "$DOCKER_ENV_FILE" \
        -v "$(pwd)/updates:/go" ${DOCKER_IMAGE} "${TUF_PARAMS}"
fi

# Cleanup temp file
rm "$DOCKER_ENV_FILE"

