#!/bin/bash

TUF="/tuf/bin/tuf${TUF_PARAMETERS:-}"
GIT="/usr/bin/git"
GH="/usr/bin/gh"
KEYTOOL="/usr/bin/php /tuf/key.php"

function prettyJson() {
    # make all *.json files pretty
    for file in **/*.json; do
        tmpfile=$(mktemp)
        jq . "$file" > "$tmpfile"
        mv "$tmpfile" "$file"
    done
}

function L_github_login() {
  $GH auth login --with-token <<<"${ACCESS_TOKEN}"
}

function L_github_create_and_merge_pr() {
  PR_URL=$($GH pr create --base ${GIT_BASE_BRANCH_NAME} --title "$1" --body "$1")
  $GH pr merge --merge "${PR_URL}"
  $GIT push origin --delete ${GIT_TARGET_BRANCH_NAME}
}

function L_git_configure() {
  $GIT config --global --add safe.directory /go
  $GIT config --global user.name "${GIT_USER_NAME}"
  $GIT config --global user.email "${GIT_USER_EMAIL}"
  $GIT config --global init.defaultBranch "${GIT_BASE_BRANCH_NAME}"
  $GIT config --global pull.rebase false
  $GIT config --global credential.https://github.com.username git
}

function L_git_init() {
  $GIT init
  $GIT remote add origin "${GIT_URL}"
  $GIT fetch origin
  $GIT checkout "${GIT_BASE_BRANCH_NAME}"
}

function L_git_update() {
  $GIT fetch origin

  if [ "$($GIT show-branch ${GIT_TARGET_BRANCH_NAME} >/dev/null 2>&1 || echo $?)" == "" ]; then
    echo "=> Checkout existing branch ${GIT_TARGET_BRANCH_NAME}"
    $GIT checkout ${GIT_TARGET_BRANCH_NAME}
  else
    echo "=> Create new branch ${GIT_TARGET_BRANCH_NAME}"
    $GIT checkout -b ${GIT_TARGET_BRANCH_NAME}
  fi

  if [ "$($GIT show-branch origin/${GIT_TARGET_BRANCH_NAME} >/dev/null 2>&1 || echo $?)" == "" ]; then
    echo "=> Set upstream origin for branch ${GIT_TARGET_BRANCH_NAME} to origin/${GIT_TARGET_BRANCH_NAME}"
    $GIT branch --set-upstream-to=origin/${GIT_TARGET_BRANCH_NAME} ${GIT_TARGET_BRANCH_NAME}
    $GIT pull
  fi

  if [ -z "$($GIT status --porcelain)" ]; then
    $GIT fetch origin
    $GIT rebase origin/${GIT_BASE_BRANCH_NAME}
  fi
}

function L_git_add_and_commit() {
  $GIT add .
  $GIT commit -m "$1"
  $GIT push -u origin ${GIT_TARGET_BRANCH_NAME}
}
