#!/bin/bash

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
SIGNER_DIR="$(dirname $SCRIPT_DIR)"
KEYS_DIR="$SIGNER_DIR/private"
SIGNER_KEYS_DIR="$SIGNER_DIR/updates/keys"

cp $KEYS_DIR/* $SIGNER_KEYS_DIR
