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
PACKAGE=$(basename $FILE .tar.zst | rev)
PACKAGE_VERSION=$(echo $PACKAGE | cut -d "-" -f 1 | rev)
PACKAGE_NAME=$(echo $PACKAGE_VERSION | rev | sed "s/-$PACKAGE_VERSION//")

if [ "$ROOT" == "" ]; then
    ROOT="/"
fi

cd $ROOT

if [ -d $ROOT/var/packages/$PACKAGE_NAME ] && [ "$2" != "-u" ]; then
    print_error "Package $PACKAGE_NAME is already installed !"
    exit 1
elif [ "$2" == "-u" ]; then
    OLD_PACKAGE_VERSION=$(cat $ROOT/var/packages/$PACKAGE_NAME/PKGINDEX | cut -d '|' -f 2)
    print_info "Updating package $PACKAGE_NAME from $OLD_PACKAGE_VERSION to $PACKAGE_VERSION..."
else
    print_info "Installing package $PACKAGE_NAME-$PACKAGE_VERSION..."
fi

echo ""
tar -xhpf $FILE

if [ "$2" == "-u" ]; then
    for line in $(cat $ROOT/var/packages/$PACKAGE_NAME/FILETREE);
    do
        if [ "$line" == "./.FILETREE"* ] || [ "$line" == "./.PKGINDEX"* ] || [ "$line" == "." ]; then
            continue
        fi

        if [ "$(cat ./.FILETREE | grep $line)" == "" ]; then
            rm -rf $line
        fi
    done

    rm -rf $ROOT/var/packages/$PACKAGE_NAME
fi

mkdir -p $ROOT/var/packages/$PACKAGE_NAME
mv .FILETREE $ROOT/var/packages/$PACKAGE_NAME/FILETREE
mv .PKGINDEX $ROOT/var/packages/$PACKAGE_NAME/PKGINDEX

print_success "Done !"
