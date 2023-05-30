#!/bin/bash

#################### STMK ####################
# Build/make system of Stock Linux distro    #
# License: GNU GENERAL PUBLIC LICENSE v3     #
##############################################

print_help() {
    echo "========================STMK========================"
    echo "| Help:                                            |"
    echo "===================================================="
    echo ""
    echo "stmk -k => Keep build files"
    echo "stmk -v => Show logs on current terminal"
    echo "stmk help | -h => Show this help menu"
    echo ""
}

# CLI parser
case "$1" in
    "help")
        print_help
        ;;
    "-h")
        print_help
        ;;
esac
