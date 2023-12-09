#!/bin/bash

if [ ! -x bw ]; then
    echo "Please download and extract the bitwarden cli client from:"
    echo " https://github.com/bitwarden/clients/releases "
    echo "and extract into the tools directory and make it executable."
    exit 255
fi

# TODO