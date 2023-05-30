#!/bin/bash

#################### STMK ####################
# Build/make system of Stock Linux distro    #
# License: GNU GENERAL PUBLIC LICENSE v3     #
##############################################

print_header() {
    echo "========================STMK========================"
    spaces=$((48 - ${#1}))
    printf "| $1 %${spaces}s|\n"
}

print_content() {
    spaces=$((48 - ${#1}))
    printf "| $1%${spaces}s |\n"
}

print_header_end() {
    echo "===================================================="
}

print_help() {
    print_header "Help:"
    print_header_end
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
