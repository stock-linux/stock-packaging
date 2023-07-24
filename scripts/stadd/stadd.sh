#!/bin/bash

#################### STADD ####################
# Packaging system of Stock Linux distro     #
# License: GNU GENERAL PUBLIC LICENSE v3     #
##############################################

print_info() {
    echo -e "\e[1;36m$1\e[0m"
}

print_error() {
    echo -e "\e[1;31m$1\e[0m"
}

print_success() {
    echo -e "\e[1;32m$1\e[0m"
}

if ! [ -f "$1" ]; then
    print_error "The provided file does not exist !"
    exit 1
fi

FILE=$(realpath $1)
PACKAGE=$(basename $FILE .tar.zst | rev)
PACKAGE_VERSION=$(echo $PACKAGE | cut -d "-" -f 1 | rev)
PACKAGE_NAME=$(echo $PACKAGE | rev | sed "s/-$PACKAGE_VERSION//")

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
    dirs_to_remove=()
    for line in $(cat $ROOT/var/packages/$PACKAGE_NAME/FILETREE);
    do
        if [ "$line" == "./.FILETREE"* ] || [ "$line" == "./.PKGINDEX"* ] || [ "$line" == "./.post-install"* ] || [ "$line" == "." ]; then
            continue
        fi

        if [ "$(cat ./.FILETREE | grep -F $line)" == "" ]; then
            if [ -d $line ]; then
                dirs_to_remove+=($line)
            else
                rm -f $line
            fi
        fi
    done

    for dir in ${dirs_to_remove[@]};
    do
        if [ -z "$(ls -A -- "$dir")" ]; then
            rm -d $dir
        fi
    done

    rm -rf $ROOT/var/packages/$PACKAGE_NAME
fi

mkdir -p $ROOT/var/packages/$PACKAGE_NAME
mv .FILETREE $ROOT/var/packages/$PACKAGE_NAME/FILETREE
mv .PKGINDEX $ROOT/var/packages/$PACKAGE_NAME/PKGINDEX

if [ -f $ROOT/.post-install ]; then
    chmod +x $ROOT/.post-install
    chroot $ROOT /.post-install
    rm $ROOT/.post-install
fi

print_success "Done !"
