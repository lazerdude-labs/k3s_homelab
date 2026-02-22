#!/bin/bash -E
# Must be run as sudo
[ `whoami` = root ] || { sudo -E "$0" "$@"; exit $?; }

directory="$(dirname "${BASH_SOURCE[0]}")"
cd $directory
