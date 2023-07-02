#!/bin/bash

DOCKER_IMAGE="joomlaprojects/docker-images:updater"

GIT_BASE_BRANCH_NAME=main
GIT_TARGET_BRANCH_NAME=next

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
            echo "$file"
            versionJSON=$(python3 semver.py "$file")
            UPDATE_VERSION="$(jq .version <<< "$versionJSON" | tr -d '"')"
            mv "$file" updates/staged/targets/
        done
    else
        echo '=> Relase Folder has no ZIP files, is this correct?'
        userConfirm
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
echo " 9 DEBUG Shell"
echo ""
localread "Action to be passed to TUF:" "" TUF_PARAMS

declare -A TUF_ACTIONS=( [1]=prepare-release [2]=sign-release [3]=release [4]=create-key [5]=sign-key [6]=commit-key [7]=update-timestamp [8]=bash [9]=DEBUG)

for key in "${!TUF_ACTIONS[@]}"; do
  if [ "$key" == "$TUF_PARAMS" ]; then
    TUF_PARAMS=${TUF_ACTIONS[$key]};
  fi
done

# Prepare standard environment parameters for the docker iamge
DOCKER_ENV_FILE=$(mktemp)
echo "$DOCKER_ENV_FILE";
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
    docker run --rm -ti \
        --env-file "$DOCKER_ENV_FILE" \
        -v "$(pwd)/updates:/go" ${DOCKER_IMAGE} \
        "${TUF_PARAMS}"
elif [[ $TUF_PARAMS = "DEBUG" ]]; then
    echo '=> Starting Shell Only for debugging'
    docker run --rm -ti \
        --entrypoint "/bin/bash" \
        --env-file "$DOCKER_ENV_FILE" \
        -v "$(pwd)/updates:/go" ${DOCKER_IMAGE}
elif [[ $TUF_PARAMS = "prepare-release" ]]; then
    checkReleaseFolder
    echo "=> Add update files and sign them"
    UPDATE_NAME="Joomla! ${UPDATE_VERSION}"
    UPDATE_DESCRIPTION="${UPDATE_NAME} Release"
    # INFO Url must be asked
    localread "Please enter the Update Info URL:" "https://www.joomla.org/announcements/release-news/" UPDATE_INFO_URL
    UPDATE_INFO_TITLE="${UPDATE_NAME} Release"
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
      localread "Please enter the Name (Person) the key belongs to:" "" SIGNATURE_ROLE_NAME
    else
      SIGNATURE_ROLE="root"
    fi
    sed -i -e "s/GIT_TARGET_BRANCH_NAME=.*/GIT_TARGET_BRANCH_NAME=key\/${GIT_BASE_BRANCH_NAME}\/${SIGNATURE_ROLE}/g" "$DOCKER_ENV_FILE"
    docker run --rm -ti \
        --env-file "$DOCKER_ENV_FILE" \
        -e SIGNATURE_ROLE="${SIGNATURE_ROLE}"\
        -e SIGNATURE_ROLE_NAME="${SIGNATURE_ROLE_NAME}"\
        -v "$(pwd)/updates:/go" ${DOCKER_IMAGE} \
        "${TUF_PARAMS}"
elif [[ $TUF_PARAMS = "sign-release" ]]; then
  localread "Please enter which Version you would like to sign:" "" UPDATE_VERSION
  sed -i -e "s/GIT_TARGET_BRANCH_NAME=.*/GIT_TARGET_BRANCH_NAME=release\/${GIT_BASE_BRANCH_NAME}\/${UPDATE_VERSION}/g" "$DOCKER_ENV_FILE"
  docker run --rm \
    --env-file "$DOCKER_ENV_FILE" \
    -v "$(pwd)/updates:/go" ${DOCKER_IMAGE} "${TUF_PARAMS}"
elif [[ $TUF_PARAMS = "release" ]]; then
  localread "Please enter which Version you would like to release:" "" UPDATE_VERSION
  sed -i -e "s/GIT_TARGET_BRANCH_NAME=.*/GIT_TARGET_BRANCH_NAME=release\/${GIT_BASE_BRANCH_NAME}\/${UPDATE_VERSION}/g" "$DOCKER_ENV_FILE"
  docker run --rm \
    --env-file "$DOCKER_ENV_FILE" \
    -v "$(pwd)/updates:/go" ${DOCKER_IMAGE} "${TUF_PARAMS}"
else
    docker run --rm \
        --env-file "$DOCKER_ENV_FILE" \
        -v "$(pwd)/updates:/go" ${DOCKER_IMAGE} "${TUF_PARAMS}"
fi

# Cleanup temp file
rm "$DOCKER_ENV_FILE"

