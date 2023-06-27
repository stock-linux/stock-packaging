#!/bin/bash

###################### HAZEL #####################
# Package builder for Stock Linux                #
# License: GNU GENERAL PUBLIC LICENSE v3         #
##################################################

print_info() {
    echo -e "\e[1;36m$1\e[0m"
}

print_error() {
    echo -e "\e[1;31m$1\e[0m"
}

print_success() {
    echo -e "\e[1;32m$1\e[0m"
}

print_help() {
    echo "Usage:"
    echo ""
    print_success "hazel"
    echo -e "\t <package|directory> [version]\t Builds a specific package or a whole directory containing multiple packages."
    print_info "\t new | -n\e[0m <path> <version>\t Creates a new package at the specified path and with the specified version."
    print_info "\t help\e[0m\t\t\t\t Shows this menu."
}

case $1 in
    help|-h|--help)
        print_help
        ;;
esac