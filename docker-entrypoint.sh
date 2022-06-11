#!/bin/bash
set -o nounset
set -o pipefail
set -o errexit

basedir=`pwd`
TUF="/tuf/bin/tuf --insecure-plaintext"
GIT="/usr/bin/git"
GH="/usr/bin/gh"

if [[ -n ${DEBUG:-} ]]; then
  echo "=> DEBUG is enabled"
  echo "=> Your passed args are: $1"
  echo "=> TUF_VERSION: ${TUF_VERSION}"
  echo "=> ACCESS_TOKEN: ${ACCESS_TOKEN}"
  echo "=> GIT_URL: ${GIT_URL}"
  set -o xtrace
fi

echo "=> Setup Github CLI"
/usr/bin/gh auth login --with-token <<< "${ACCESS_TOKEN}"

echo "=> Configure git"
$GIT config --global user.name "${GIT_USER_NAME}"
$GIT config --global user.email "${GIT_USER_EMAIL}"
$GIT config --global init.defaultBranch "${GIT_BASE_BRANCH_NAME}"
$GIT config --global pull.rebase false;
$GIT config --global credential.https://github.com.username git

# If we already are in a directory with a git repository we assume it's the
# update repository and fetch the latest commit. If we are not in a git
# repository we create a new one and pull the upstream repository
if [[ ! -d .git ]]; then
  echo "=> Initially checkout repository"
  $GIT init
  $GIT remote add origin "${GIT_URL}"
  $GIT fetch origin
  $GIT checkout "${GIT_BASE_BRANCH_NAME}"

fi

echo "=> Update repository version"
$GIT fetch origin

if [ "`$GIT show-branch ${GIT_TARGET_BRANCH_NAME} > /dev/null || echo $?`" == "" ]; then
  $GIT checkout ${GIT_TARGET_BRANCH_NAME}
else
  $GIT checkout -b ${GIT_TARGET_BRANCH_NAME}
fi

if [ "`$GIT show-branch origin/${GIT_TARGET_BRANCH_NAME} > /dev/null || echo $?`" == "" ]; then
  $GIT branch --set-upstream-to=origin/${GIT_TARGET_BRANCH_NAME} ${GIT_TARGET_BRANCH_NAME}
  $GIT pull
fi

$GIT fetch origin
$GIT rebase origin/${GIT_BASE_BRANCH_NAME}

case "$1" in
  "bash")
      /bin/bash
      ;;
  "update-timestamp")
      echo "=> TUF Updation timestamp"
      $TUF timestamp
      $TUF commit
      $GIT commit -am "Update timestamp"
      $GIT push -u origin ${GIT_TARGET_BRANCH_NAME}
      ;;
  "prepare-release")
      sed "s/\$VERSION/${UPDATE_VERSION}/g" $basedir/templates/update-info-4.json | tee /tmp/update-info.json
      cat <<< $(jq '.["description"] = "'"${UPDATE_DESCRIPTION}"'"' /tmp/update-info.json) > /tmp/update-info.json
      cat <<< $(jq '.["infourl"]["url"] = "'"${UPDATE_INFO_URL}"'"' /tmp/update-info.json) > /tmp/update-info.json
      cat <<< $(jq '.["infourl"]["title"] = "'"${UPDATE_INFO_TITLE}"'"' /tmp/update-info.json) > /tmp/update-info.json
      cat <<< $(jq '.["name"] = "'"${UPDATE_NAME}"'"' /tmp/update-info.json) > /tmp/update-info.json
      cat <<< $(jq '.["version"] = "'"${UPDATE_VERSION}"'"' /tmp/update-info.json) > /tmp/update-info.json
      $TUF add --custom="$(jq -c '.' /tmp/update-info.json)"
      $GIT add .
      $GIT commit -m "Prepare ${UPDATE_VERSION}"
      $GIT push -u origin ${GIT_TARGET_BRANCH_NAME}
      ;;
  "sign-release")
      $TUF sign targets.json
      $GIT add .
      $GIT commit -m "Sign Release ${GIT_TARGET_BRANCH_NAME}"
      $GIT push -u origin ${GIT_TARGET_BRANCH_NAME}
      ;;
  "release")
      $TUF snapshot
      $TUF timestamp
      $TUF commit
      $GIT add .
      $GIT commit -m "Release: ${GIT_TARGET_BRANCH_NAME}"
      $GIT push -u origin ${GIT_TARGET_BRANCH_NAME}
      PR_URL=$($GH pr create --base ${GIT_BASE_BRANCH_NAME} --title "Release: ${GIT_TARGET_BRANCH_NAME}"  --body "Release: ${GIT_TARGET_BRANCH_NAME}")
      $GH pr merge --merge "${PR_URL}"
      ;;
  "create-signature")
      tmpfile=`mktemp`
      $TUF gen-key --expires=1825 ${SIGNATURE_ROLE} | tee $tmpfile
      keyid=`cat $tmpfile | awk '{print $6}'`

      jq ". + {\"${keyid}\":\"${SIGNATURE_ROLE_NAME}\"}" < metadata/keys.json > $tmpfile
      mv $tmpfile metadata/keys.json

      $TUF payload root.json > staged/root.json.payload
      $GIT add .
      $GIT commit -m "Prepare key for Role ${SIGNATURE_ROLE} by ${SIGNATURE_ROLE_NAME}"
      $GIT push -u origin ${GIT_TARGET_BRANCH_NAME}
      ;;
  "sign-signature")
      $TUF sign-payload --role=${SIGNATURE_ROLE} staged/${SIGNATURE_ROLE}.json.payload > staged/${SIGNATURE_ROLE}.json.sigs.$RANDOM
      $GIT add .
      $GIT commit -m "Signed signature key"
      $GIT push -u origin ${GIT_TARGET_BRANCH_NAME}
      ;;
  "commit-signature")
      jq -s add staged/${SIGNATURE_ROLE}.json.sigs.* > staged/${SIGNATURE_ROLE}.json.sigs
      $TUF add-signatures --signatures staged/${SIGNATURE_ROLE}.json.sigs ${SIGNATURE_ROLE}.json
      rm staged/${SIGNATURE_ROLE}.json.*
      $TUF snapshot
      $TUF timestamp
      $TUF commit
      $GIT add .
      $GIT commit -m "Add signature key"
      $GIT push -u origin ${GIT_TARGET_BRANCH_NAME}
      PR_URL=$($GH pr create --base ${GIT_BASE_BRANCH_NAME} --title "Add signature key" --body "Add signature key")
      $GH pr merge --merge "${PR_URL}"
      ;;
  *)
      $TUF "$1"
      ;;
esac
