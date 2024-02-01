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
    # Using workaround because OSX supports only bash 3.2 which doesn't support
    #read "-${L_ADDITIONAL}rep" "${L_LABEL} " -i "${L_DEFAULT}" "${L_VAR}"

    # BASH 3.2 compatible code start
    if read "-${L_ADDITIONAL}rep" "${L_LABEL}" "${L_VAR}" && [[ ${L_VAR} ]]; then
      return 0
    else
      printf -v "${L_VAR}" %s "${L_DEFAULT}"
    fi
    # BASH 3.2 compatible code end
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

localread "Github Personal Access Token:" "" ACCESS_TOKEN s
if [ -z "${ACCESS_TOKEN}" ]; then echo "Aborting no Personal Access Token given."; exit 1; fi

echo ""
echo "Supported actions"
echo ""
echo "Release Actions:"
echo " r1 prepare-release"
echo " r2 sign-release"
echo " r3 release"
echo ""
echo "Signature Actions:"
echo " k1 create-key"
echo " k2 remove-key"
echo " k3 sign-keys"
echo " k4 commit-keys"
echo ""
echo "Maintenance Actions:"
echo " m1 update-timestamp"
echo " m2 bash"
echo " m3 clean docker environment"
echo " m4 DEBUG Shell"
echo ""
echo "q Exit"
echo ""
localread "Action to be passed to TUF:" "" TUF_PARAMS

# Using switch/case workaround because OSX supports only bash 3.2 which doesn't support
#declare -A TUF_ACTIONS=( [r1]=prepare-release [r2]=sign-release [r3]=release [k1]=create-key [k2]=remove-key [k3]=sign-keys [k4]=commit-keys [m1]=update-timestamp [m2]=bash [m3]=clean-docker [m4]=DEBUG [q]=quit)

#for key in "${!TUF_ACTIONS[@]}"; do
#  if [ "$key" == "$TUF_PARAMS" ]; then
#    TUF_PARAMS=${TUF_ACTIONS[$key]};
#  fi
#done

# BASH 3.2 compatible code start
case $TUF_PARAMS in
  r1)
    TUF_PARAMS="prepare-release"
    ;;
  r2)
    TUF_PARAMS="sign-release"
    ;;
  r3)
    TUF_PARAMS="release"
    ;;
  k1)
    TUF_PARAMS="create-key"
    ;;
  k2)
    TUF_PARAMS="remove-key"
    ;;
  k3)
    TUF_PARAMS="sign-keys"
    ;;
  k4)
    TUF_PARAMS="commit-keys"
    ;;
  m1)
    TUF_PARAMS="update-timestamp"
    ;;
  m2)
    TUF_PARAMS="bash"
    ;;
  m3)
    TUF_PARAMS="clean-docker"
    ;;
  m4)
    TUF_PARAMS="DEBUG"
    ;;
  q)
    TUF_PARAMS="quit"
    ;;
esac
# BASH 3.2 compatible code end

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

if [[ $TUF_PARAMS = "quit" ]]; then
  echo "=> Exit"
  exit 0
fi


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
elif [[ $TUF_PARAMS = "create-key" || $TUF_PARAMS = "remove-key" || $TUF_PARAMS = "sign-keys" || $TUF_PARAMS = "commit-keys" ]]; then
    case "$TUF_PARAMS" in
      "create-key")
        echo "=> Create a key"
        ;;
      "remove-key")
        echo "=> Remove a key"
        ;;
      "sign-keys")
        echo "=> Sign keys"
        ;;
      "commit-keys")
        echo "=> Commit keys"
        ;;
    esac

    if [[ $TUF_PARAMS = "create-key" || $TUF_PARAMS = "remove-key" ]]; then
      localread "Please enter the Role (root, targets, snapshot, timestamp):" "" SIGNATURE_ROLE
    else
      loadkeys
      checkkey "root"
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
    -v "$(pwd)/updates:/go" ${DOCKER_IMAGE} "clean-git"
fi

# Cleanup temp file
rm "$DOCKER_ENV_FILE"

