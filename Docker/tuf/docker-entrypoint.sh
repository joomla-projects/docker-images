#!/bin/bash
set -o nounset
set -o pipefail
set -o errexit

basedir=$(pwd)

. /tuf/functions.inc.sh

echo "=> Setup Github CLI"
L_github_login

echo "=> Configure git"
L_git_configure

# If we already are in a directory with a git repository we assume it's the
# update repository and fetch the latest commit. If we are not in a git
# repository we create a new one and pull the upstream repository
if [[ ! -d .git ]]; then
  echo "=> Initially checkout repository"
  L_git_init
  if [[ ! -d keys ]]; then
    mkdir keys
  fi
  if [[ ! -d staged ]]; then
    mkdir staged
  fi
else
  $GIT fetch origin
fi

if [[ "$1" = "sign-release" || "$1" = "release" || "$1" = "sign-key" || "$1" = "commit-key" ]]; then
  if [ "$($GIT show-branch origin/${GIT_TARGET_BRANCH_NAME} >/dev/null 2>&1 || echo $?)" != "" ]; then
    echo "Branch ${GIT_TARGET_BRANCH_NAME} doesn't exists. Aborting..."
    exit 1
  fi
fi

echo "=> Update repository version"
L_git_update

. /go/config.env

case "$1" in
  "bash")
      /bin/bash
      ;;
  "update-timestamp")
      echo "=> TUF Updation timestamp"
      $TUF timestamp --expires=${TUF_EXPIRE_TIMESTAMP}
      $TUF commit
      L_git_add_and_commit "Update timestamp"
      ;;
  "prepare-release")
      if [ "$($GIT show-branch origin/${GIT_TARGET_BRANCH_NAME} >/dev/null 2>&1 || echo $?)" == "" ]; then
        echo "Version branch ${GIT_TARGET_BRANCH_NAME} already exists. Aborting..."
        exit 1
      fi
      sed -e "s/\$VERSION/${UPDATE_VERSION}/g" -e "s/\$DASHVERSION/${UPDATE_VERSION//./-}/g" $basedir/templates/update-info-$(cut -d '.' -f 1 <<< "$UPDATE_VERSION").json | tee /tmp/update-info.json
      cat <<< $(jq '.["description"] = "'"${UPDATE_DESCRIPTION}"'"' /tmp/update-info.json) > /tmp/update-info.json
      cat <<< $(jq '.["infourl"]["url"] = "'"${UPDATE_INFO_URL}"'"' /tmp/update-info.json) > /tmp/update-info.json
      cat <<< $(jq '.["infourl"]["title"] = "'"${UPDATE_INFO_TITLE}"'"' /tmp/update-info.json) > /tmp/update-info.json
      cat <<< $(jq '.["name"] = "'"${UPDATE_NAME}"'"' /tmp/update-info.json) > /tmp/update-info.json
      cat <<< $(jq '.["version"] = "'"${UPDATE_VERSION}"'"' /tmp/update-info.json) > /tmp/update-info.json
      $TUF add --custom="$(jq -c '.' /tmp/update-info.json)"
      L_git_add_and_commit "Prepare ${UPDATE_VERSION}"
      ;;
  "sign-release")
      $TUF sign targets.json
      L_git_add_and_commit "Sign Release ${GIT_TARGET_BRANCH_NAME}"
      ;;
  "release")
      $TUF snapshot --expires=${TUF_EXPIRE_SNAPSHOT}
      L_git_add_and_commit "Release: ${GIT_TARGET_BRANCH_NAME}"
      L_github_create_and_merge_pr "Release: ${GIT_TARGET_BRANCH_NAME}"
      ;;
  "create-key")
      if [ "$(ls -A staged)" != "" ]; then
        echo "Error: stage is not empty aborting"
        exit 1
      fi

      tmpfile=$(mktemp)
      $TUF gen-key --expires=${TUF_EXPIRE_KEY} ${SIGNATURE_ROLE} | tee $tmpfile
      keyid=$(cat $tmpfile | awk '{print $7}')

      jq ". + {\"${keyid}\":\"${SIGNATURE_ROLE_NAME}\"}" < metadata/keys.json > $tmpfile
      mv $tmpfile metadata/keys.json

      if [ "${SIGNATURE_ROLE}" == "root" ] || [ "${SIGNATURE_ROLE}" == "targets"  ]; then
        jq ".signed.roles.snapshot.keyids += [\"${keyid}\"]" < staged/root.json > $tmpfile
        mv $tmpfile staged/root.json
      fi

      # Extract the public key
      publicKey=$(cat staged/root.json | jq -r '.signed.keys."'${keyid}'".keyval.public')

      cat staged/root.json | jq -r '.signed.keys."${keyid}".keyval.public'

      $KEYTOOL add --keyId="${keyid}" --role="${SIGNATURE_ROLE}" --name="${SIGNATURE_ROLE_NAME}" --public-key="${publicKey}"

      $TUF payload root.json > staged/root.json.payload
      L_git_add_and_commit "Prepare key for Role ${SIGNATURE_ROLE} by ${SIGNATURE_ROLE_NAME}"
      ;;
  "remove-key")
      if [ "$(ls -A staged)" != "" ]; then
        echo "Error: stage is not empty aborting"
        exit 1
      fi

      tmpfile=$(mktemp)

      keyid=$($KEYTOOL list --name="${SIGNATURE_ROLE_NAME}" --format="keyId")

      $TUF revoke-key --expires=${TUF_EXPIRE_KEY} ${SIGNATURE_ROLE} ${keyid}

      $KEYTOOL remove --keyId="${keyid}" --role="${SIGNATURE_ROLE}"

      $TUF payload root.json > staged/root.json.payload
      L_git_add_and_commit "Prepare removal of key for Role ${SIGNATURE_ROLE} by ${SIGNATURE_ROLE_NAME}"
      ;;
  "sign-keys")
      $TUF sign-payload --role=${SIGNATURE_ROLE} staged/${SIGNATURE_ROLE}.json.payload > staged/${SIGNATURE_ROLE}.json.sigs.$RANDOM
      L_git_add_and_commit "Signed signature key"
      ;;
  "commit-keys")
      jq -s add staged/${SIGNATURE_ROLE}.json.sigs.* > staged/${SIGNATURE_ROLE}.json.sigs
      $TUF add-signatures --signatures staged/${SIGNATURE_ROLE}.json.sigs ${SIGNATURE_ROLE}.json
      rm staged/${SIGNATURE_ROLE}.json.*
      $TUF snapshot --expires=${TUF_EXPIRE_SNAPSHOT}
      L_git_add_and_commit "Add signature key"
      L_github_create_and_merge_pr "Add signature key"
      ;;
  "clean-git")
      echo "=> Remove all local branches which don't exists on upstream"
      git fetch --prune && git branch -vv | grep ': gone]' | awk '{print $1}' | xargs -r git branch -d
      echo "=> Repo clean"
      ;;
  "noop")
      exit 0
      ;;
  *)
      $TUF "$1"
      ;;
esac
