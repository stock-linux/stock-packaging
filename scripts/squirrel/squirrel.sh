#!/bin/bash

#################### SQUIRREL ####################
# Package manager of Stock Linux distro          #
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
    print_success "squirrel"
    print_info "\t install\e[0m <package|list|file>\t Installs a package (can be a name, a 'list' name or a file)."
    print_info "\t remove\e[0m  <package|list>\t\t Removes a package/list (and its not-used dependencies)."
    print_info "\t upgrade\e[0m [package|list]\t\t Upgrades all the installed packages on the system or just a package/list."
    print_info "\t info\e[0m    <package|list>\t\t Prints information about the specified package/list."
    print_info "\t search\e[0m [-l|--list] <expression> Searches the packages or lists (with the -l option) containing the specified expression in their names."
}

print_help