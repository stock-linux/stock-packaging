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

check_pkg_or_list_exists() {
    PACKAGE_TYPE="none"
    for repo in $ROOT/var/squirrel/repos/*; do
        while IFS= read -r line; do
            if [[ "$line" == "$1 "* ]]; then
                PACKAGE_TYPE="pkg"
                PACKAGE_NAME=$(echo $line | cut -d ' ' -f 1)
                PACKAGE_VERSION=$(echo $line | cut -d ' ' -f 2)
                PACKAGE_RELEASE=$(echo $line | cut -d ' ' -f 3)
                PACKAGE_SUBPATH=$(echo $line | cut -d ' ' -f 4)
                PACKAGE_REPO=$(basename $repo)
            fi
            if [[ "$line" == "$1" ]]; then
                PACKAGE_TYPE="list"
                PACKAGE_REPO=$(basename $repo)
            fi
        done < $repo/INDEX
    done
}

check_pkg_installed() {
    if [ -d $ROOT/var/packages/$1 ]; then
        print_error "Package '$1' already installed."
        exit 1
    fi
}

check_pkg_installed_no_exit() {
    PACKAGE_INSTALLED=false
    if [ -d $ROOT/var/packages/$1 ]; then
        PACKAGE_INSTALLED=true
    fi
}

download_file() {
    if [ -f $1 ]; then
        cp $1 $2
    else
        curl -s -o $2 $1
        if [ $? != 0 ]; then
            rm $2
            print_error "An error occured during the download !"
            exit 1
        fi
    fi
}

download_pkg() {
    check_pkg_installed_no_exit $1
    check_pkg_or_list_exists $1
    if $PACKAGE_INSTALLED; then
        return
    fi
    get_repo_url $PACKAGE_REPO
    PACKAGE_URL=$REPO_URL/$PACKAGE_SUBPATH
    [ -f $ROOT/var/squirrel/cache/${1}_PKGINDEX ] && return
    download_file $(dirname $PACKAGE_URL)/.PKGINDEX $ROOT/var/squirrel/cache/${1}_PKGINDEX 
    read_deps_from_index $ROOT/var/squirrel/cache/${1}_PKGINDEX
    for dep in ${deps[@]}; do
        if [ "$dep" != "$1" ]; then
            download_pkg $dep
        fi
    done
    print_info "Downloading $1..."
    check_pkg_installed_no_exit $1
    check_pkg_or_list_exists $1
    get_repo_url $PACKAGE_REPO
    PACKAGE_URL=$REPO_URL/$PACKAGE_SUBPATH
    download_file $PACKAGE_URL $ROOT/var/squirrel/cache/$(basename $PACKAGE_URL)
    print_success "Download succeeded !"
}

get_repo_lists() {
    mkdir -p $ROOT/var/squirrel/lists/
    while IFS= read -r line; do
        if [[ "$line" != *".tar.zst" ]]; then
            download_file $REPO_URL/$line.txt $ROOT/var/squirrel/lists/$line
        fi
    done < $ROOT/var/squirrel/repos/$REPO_NAME/INDEX
}
get_repo_url() {
    while IFS= read -r line; do
        if [[ "$line" == "$1 "* ]]; then
            REPO_URL=$(echo $line | cut -d ' ' -f 2)
        fi
    done < $CONF_PATH
}

install_pkg() {
    read_deps_from_index $ROOT/var/squirrel/cache/${1}_PKGINDEX
    rm $ROOT/var/squirrel/cache/${1}_PKGINDEX
    for dep in ${deps[@]}; do
        check_pkg_installed_no_exit $dep
        if [ "$dep" != "$1" ] && ! $PACKAGE_INSTALLED; then
            install_pkg $dep
        fi
    done
    check_pkg_installed_no_exit $1
    check_pkg_or_list_exists $1
    get_repo_url $PACKAGE_REPO
    PACKAGE_URL=$REPO_URL/$PACKAGE_SUBPATH
    ROOT=$ROOT CONF_PATH=$CONF_PATH squirrel install $ROOT/var/squirrel/cache/$(basename $PACKAGE_URL) -i
    rm $ROOT/var/squirrel/cache/$(basename $PACKAGE_URL)
}

sync() {
    print_info "Syncing repos..."
    while IFS= read -r line; do
        REPO_NAME=$(echo $line | cut -d ' ' -f 1)
        REPO_URL=$(echo $line | cut -d ' ' -f 2)

        mkdir -p $ROOT/var/squirrel/repos/$REPO_NAME
        download_file $REPO_URL/INDEX $ROOT/var/squirrel/repos/$REPO_NAME/INDEX
        get_repo_lists $REPO_NAME
    done < $CONF_PATH
    print_success "Done !"
}

if [ "$ROOT" == "" ]; then
    ROOT="/"
fi

if [ "$CONF_PATH" == "" ]; then
    CONF_PATH=$ROOT/etc/squirrel.conf
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

            check_pkg_installed $PACKAGE_NAME
            
            tar -xf $2 ./.PKGINDEX
            read_deps_from_index ./.PKGINDEX

            if [ "${@: -1}" != "-i" ]; then
                for dep in ${deps[@]}; do
                    if [ "$dep" != "$PACKAGE_NAME" ]; then
                        ROOT=$ROOT CONF_PATH=$CONF_PATH squirrel install $dep
                    fi
                done
            fi

            ROOT=$ROOT stadd $2
        else
            mkdir -p $ROOT/var/squirrel/cache/
            ALL_PACKAGES_INSTALLED=true
            for pkg in ${@:2}; do
                check_pkg_installed_no_exit $pkg
                if ! $PACKAGE_INSTALLED; then
                    ALL_PACKAGES_INSTALLED=false
                fi

                check_pkg_or_list_exists $pkg
                if [ "$PACKAGE_TYPE" == "none" ]; then
                    print_error "Package '$pkg' does not exist !"
                    exit 1
                fi
            done
            if ! $ALL_PACKAGES_INSTALLED; then
                for pkg in ${@:2}; do
                    check_pkg_or_list_exists $pkg
                    if [ "$PACKAGE_TYPE" == "pkg" ]; then
                        download_pkg $pkg
                    fi

                    if [ "$PACKAGE_TYPE" == "list" ]; then
                        pkgs=()
                        while IFS= read -r line; do
                            pkgs+=($line)
                        done < $ROOT/var/squirrel/lists/$2
                        ROOT=$ROOT CONF_PATH=$CONF_PATH squirrel install ${pkgs[@]}
                    fi
                done
                [ "$PACKAGE_TYPE" != "list" ] && echo ""
                for pkg in ${@:2}; do
                    check_pkg_installed_no_exit $pkg
                    check_pkg_or_list_exists $pkg
                    if $PACKAGE_INSTALLED; then
                        continue
                    fi
                    [ "$PACKAGE_TYPE" == "list" ] && continue
                    install_pkg $pkg
                done
            else
                if [ ${#@} == 2 ]; then
                    print_error "Package '$2' is already installed !"
                    exit
                fi
                print_error "All the packages are already installed !"
                exit
            fi
        fi
        ;;

    sync)
        sync
        ;;
esac

####### FUTURE CODE OF THE BUILD TOOL TO GENERATE THE INDEX FILE #######
#for file in $(find -iname "*.tar.zst"); do
#    PACKAGE_NAME=$(cat $(dirname $file)/.PKGINDEX | cut -d '|' -f 1)
#    PACKAGE_VERSION=$(cat $(dirname $file)/.PKGINDEX | cut -d '|' -f 2)
#    PACKAGE_RELEASE=$(cat $(dirname $file)/.PKGINDEX | cut -d '|' -f 3)
#    echo "$PACKAGE_NAME $PACKAGE_VERSION $PACKAGE_RELEASE $file" >> INDEX
#done
#for file in $(find -maxdepth 1 -iname "*.txt"); do
#    echo "$(basename $file .txt)" >> INDEX
#done

