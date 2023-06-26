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
    print_info "\t search\e[0m <expression> [-l|--list] Searches the packages or lists (with the -l option) containing the specified expression in their names."
    print_info "\t help\e[0m\t\t\t\t Shows this menu."
}

read_deps_from_index() {
    deps=()
    IFS=',' read -r -a deps <<< "$(cat $1 | cut -d '|' -f 7)"
}

if [ "$ROOT" == "" ]; then
    ROOT="/"
fi

case $1 in
    help|-h|--help)
        print_help
        ;;
    install)
        if [ -f $2 ]; then
            PACKAGE=$(basename $2 .tar.zst | rev)
            PACKAGE_VERSION=$(echo $PACKAGE | cut -d "-" -f 1 | rev)
            PACKAGE_NAME=$(echo $PACKAGE | rev | sed "s/-$PACKAGE_VERSION//")

            if [ -d $ROOT/var/packages/$PACKAGE_NAME ]; then
                print_error "Package '$PACKAGE_NAME' already installed."
                exit 1
            fi

            tar -xf $2 .PKGINDEX
            read_deps_from_index ./.PKGINDEX

            for dep in ${deps[@]}; do
                squirrel install $dep
            done
            
            stadd $2
        fi
        ;;
esac