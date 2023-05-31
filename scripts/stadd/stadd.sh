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
PACKAGE=${FILE/.tar.zst/}
PACKAGE_NAME=$(echo $1 | cut -d "-" -f 1)
PACKAGE_VERSION=$(echo $1 | cut -d "-" -f 2)

if [ "$ROOT" == "" ]; then
    ROOT="/"
fi

cd $ROOT
print_info "Installing package $PACKAGE_NAME-$PACKAGE_VERSION..."
echo ""
tar -xhpf $FILE

mkdir -p $ROOT/var/packages/$PACKAGE_NAME
mv .FILETREE $ROOT/var/packages/$PACKAGE_NAME/FILETREE
mv .PKGINDEX $ROOT/var/packages/$PACKAGE_NAME/PKGINDEX
echo $(cat $ROOT/var/packages/$PACKAGE_NAME/PKGINDEX) >> $ROOT/var/packages/INDEX

print_success "Done !"