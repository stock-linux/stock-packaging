#!/bin/bash

#################### STADD ####################
# Packaging system of Stock Linux distro     #
# License: GNU GENERAL PUBLIC LICENSE v3     #
##############################################

source "$(dirname -- "$0")/../utils.sh"

print_help() {
    print_header "Help:"
    print_content ""
    print_content "stadd <package_file>"
    print_content ""
    print_header_end
}

# CLI Parser
if [ "$1" == "help" ] || [ "$1" == "-h" ]; then
    print_help
fi

if ! [ -f "$1" ]; then
    print_error "The provided file does not exist !"
    exit 1
fi

FILE=$(realpath $1)

if [ "$ROOT" == "" ]; then
    ROOT="/"
fi