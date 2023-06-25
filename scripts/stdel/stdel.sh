#!/bin/bash

#################### STDEL ####################
# Packaging system of Stock Linux distro    #
# License: GNU GENERAL PUBLIC LICENSE v3     #
##############################################

print_info() {
    echo -e "\e[1;34m$1\e[0m"
}

print_error() {
    echo -e "\e[1;31m$1\e[0m"
}

print_success() {
    echo -e "\e[1;32m$1\e[0m"
}

if [ "$ROOT" == "" ]; then
    ROOT="/"
fi

cd $ROOT

if [ ! -d $ROOT/var/packages/$PACKAGE_NAME ] && [ "$2" != "-u" ]; then
    print_error "Package $PACKAGE_NAME is not installed !"
    exit 1
fi

print_info "Deleting package $PACKAGE_NAME..."
dirs_to_remove=()
for line in $(cat $ROOT/var/packages/$PACKAGE_NAME/FILETREE);
do
    if [ "$line" == "./.FILETREE"* ] || [ "$line" == "./.PKGINDEX"* ] || [ "$line" == "./.post-install"* ] || [ "$line" == "." ]; then
        continue
    fi

    if [ -d $line ]; then
        dirs_to_remove+=($line)
    else
        rm -f $line
    fi
done

for dir in ${dirs_to_remove[@]};
do
    if [ -z "$(ls -A -- "$dir")" ]; then
        rm -d $dir
    fi
done

rm -rf $ROOT/var/packages/$PACKAGE_NAME
print_success "Done !"