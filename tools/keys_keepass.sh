#!/bin/bash

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
SIGNER_DIR="$(dirname $SCRIPT_DIR)"
KEYS_DIR="$SIGNER_DIR/private"
SIGNER_KEYS_DIR="$SIGNER_DIR/updates/keys"

if [ -f $SIGNER_DIR/.env ];
then
  . $SIGNER_DIR/.env
fi

function exportKey() {
  L_ENTRY=$1
  L_FILE=$2

  if [ ! -z "${L_ENTRY}" ];
  then
    if [ ! -f "$KEYS_DIR/$L_FILE" ];
    then
      keepassxc-cli attachment-export "${KEY_ADAPTER_KEEPASS_DATABASE_PATH}" ${KEY_ADAPTER_KEEPASS_ADDITIONAL} "${L_ENTRY}" $L_FILE "$KEYS_DIR/$L_FILE"
    fi
  fi

}

exportKey "${KEY_ADAPTER_KEEPASS_ROOT_KEY}" "root.json"
exportKey "${KEY_ADAPTER_KEEPASS_TARGETS_KEY}" "targets.json"
exportKey "${KEY_ADAPTER_KEEPASS_SNAPSHOT_KEY}" "snapshot.json"
exportKey "${KEY_ADAPTER_KEEPASS_TIMESTAMP_KEY}" "timestamp.json"

cp $KEYS_DIR/* $SIGNER_KEYS_DIR
