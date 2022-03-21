#!/bin/bash
set -o nounset
set -o pipefail
set -o errexit


if [[ -n ${DEBUG:-} ]]; then
  echo "=> DEBUG is enabled"
  echo "=> Your passed args are: $1"
  echo "=> TUF_VERSION: ${TUF_VERSION}"
  echo "=> ACCESS_TOKEN: ${ACCESS_TOKEN}"
  echo "=> GIT_URL: ${GIT_URL}"
  set -o xtrace
fi

echo "=> Setup Github CLI"
#/usr/bin/gh
/usr/bin/gh auth login --with-token <<< "${ACCESS_TOKEN}"

echo "=> Configure git"
/usr/bin/git config --global user.name "${GIT_USER_NAME}"
/usr/bin/git config --global user.email "${GIT_USER_EMAIL}"
/usr/bin/git config --global pull.rebase false;
/usr/bin/git config --global credential.https://github.com.username git

if [[ -d .git ]]; then
  /usr/bin/git checkout "${GIT_BRANCH_NAME}" .
  /usr/bin/git pull
  /usr/bin/git fetch origin
  /usr/bin/git rebase origin/main
else
  /usr/bin/git init
  /usr/bin/git remote add origin "${GIT_URL}"
  /usr/bin/git fetch origin
  /usr/bin/git checkout "${GIT_BRANCH_NAME}"
  /usr/bin/git rebase origin/main
fi

if [[ $1 == "update-timestamp" ]]; then
  echo "=> TUF Updation timestamp"
  /tuf/bin/tuf timestamp
  /tuf/bin/tuf commit
  /usr/bin/git commit -am "Update timestamp"
  /usr/bin/git push
elif [[ $1 == "release" ]]; then
  /tuf/bin/tuf snapshot
  /tuf/bin/tuf timestamp
  /tuf/bin/tuf commit
  /usr/bin/git add .
  /usr/bin/git commit -m "Release: ${GIT_BRANCH_NAME}"
  /usr/bin/git push
  PR_URL=$(/usr/bin/gh pr create --base main --title "Release: ${GIT_BRANCH_NAME}")
  /usr/bin/gh pr merge "${PR_URL}"
elif [[ $1 == "gen-template" ]]; then
  sed "s/\$VERSION/${UPDATE_VERSION}/g" /go/templates/update-info-4.json | tee /tmp/update-info.json
  cat <<< $(jq '.["description"] = "'"${UPDATE_DESCRIPTION}"'"' /tmp/update-info.json) > /tmp/update-info.json
  cat <<< $(jq '.["infourl"]["url"] = "'"${UPDATE_INFO_URL}"'"' /tmp/update-info.json) > /tmp/update-info.json
  cat <<< $(jq '.["infourl"]["title"] = "'"${UPDATE_INFO_TITLE}"'"' /tmp/update-info.json) > /tmp/update-info.json
  cat <<< $(jq '.["name"] = "'"${UPDATE_NAME}"'"' /tmp/update-info.json) > /tmp/update-info.json
  cat <<< $(jq '.["version"] = "'"${UPDATE_VERSION}"'"' /tmp/update-info.json) > /tmp/update-info.json
  /tuf/bin/tuf add --custom="$(jq -c '.' /tmp/update-info.json)"
  /usr/bin/git add .
  /usr/bin/git commit -m "Prepare ${UPDATE_VERSION}"
  /usr/bin/git push
else
  /tuf/bin/tuf "$1"
fi
