#!/bin/bash

#################### STMK ####################
# Build/make system of Stock Linux distro    #
# License: GNU GENERAL PUBLIC LICENSE v3     #
##############################################

source '$("dirname -- "$0")/../utils.sh'

check_variables() {
    ERROR=false
    if [ "$name" == "" ]; then
        print_error "Package name not set !"
        ERROR=true
    fi

    if [ "$version" == "" ]; then
        print_error "Package version not set !"
        ERROR=true
    fi

    if [ "$release" == "" ]; then
        print_error "Package release not set !"
    fi

    if [ "$description" == "" ]; then
        print_error "Package description not set !"
        ERROR=true
    fi

    if [ "$source" == "" ]; then
        print_error "Package source not set !"
        ERROR=true
    fi

    if [ "$packager" == "" ]; then
        print_error "Packager not set !"
        ERROR=true
    fi

    if $ERROR ; then
        exit 1
    fi
}

print_variables() {
    print_header "Package information:"
    print_content ""
    print_content "Package name: $name"
    print_content "Package version: $version"
    print_content "Package description: $description"
    print_content ""
    print_content "Workdir: $WORKDIR"
    print_header_end
}

print_warning() {
    echo -e "\e[1;33m$1\e[0m"
}

unpack() {
    tar -xf $name-$version.tar.*
    if [ -d $name-$version ]; then
        cd $name-$version
    fi
}

build() {
    ./configure --prefix=/usr
    make
    make DESTDIR=$PKG install
}

pack() {
    cd $PKG
    # Remove unneeded and harmful LA files
    if [ "$KEEP_LA" == "" ] || !$KEEP_LA; then
        for file in $(find . -type f -name "*.la");
        do
            rm $file
        done
    fi

    find . > .FILETREE
    tar -I 'zstd --ultra -22' -cf ../$name-$version.tar.zst .
}

read_elf_deps() {
    DEPS=()
    for file in $(find);
    do
        FILETYPE=$(file $file | cut -d ' ' -f 2)
        if [ "$FILETYPE" == "ELF" ]; then
            ARCH=$(file $file | cut -d ' ' -f 3)
            LIBRARIES=$(readelf -d $file | grep 'NEEDED' | cut -d ':' -f 2 | cut -d '[' -f 2 | cut -d ']' -f 1)
            for library in $LIBRARIES; do
                for package in $INSTALLED_PACKAGES_DIR/*;
                do
                    PACKAGE_NAME=$(basename $package)
                    if ([ "$ARCH" == "64-bit" ] && [[ "$PACKAGE_NAME" == "lib32-"* ]]) || ([ "$ARCH" == "32-bit" ] && [[ "$PACKAGE_NAME" != "lib32-"* ]]); then
                        continue
                    fi

                    if [ "$(cat $package/FILETREE | grep $library)" != "" ]; then
                        if ! [[ " ${DEPS[*]} " == *" $PACKAGE_NAME "* ]]; then
                            DEPS+="$PACKAGE_NAME"
                        fi
                    fi
                done
            done
        fi
    done
}

# CLI parser
case "$1" in
    "help")
        print_help
        ;;
    "-h")
        print_help
        ;;
    *)
        BASEDIR=$PWD
        source ./recipe
        WORKDIR=$(mktemp -d)
        cd $WORKDIR
        # Check the presence of needed variables
        check_variables

        # Print package information
        print_variables

        echo ""

        # Download sources
        for sourceURL in ${source[@]};
        do
            URL=$(echo ${sourceURL} | cut -d "#" -f 1)
            if [ $(echo ${sourceURL} | cut -d "#" -f 2) == $URL ]; then
                FILENAME=${sourceURL##*/}
            else
                FILENAME=$(echo ${sourceURL} | cut -d "#" -f 2)
            fi

            curl -o $FILENAME $URL
        done

        echo ""

        PKG=$WORKDIR/dist
        mkdir $PKG

        unpack
        if [ "$STMK_DIR" != "" ]; then
            build &> $STMK_DIR/logs/$name-build-$(date '+%Y-%m-%d--%H:%M').out
        else
            if [ "$VERBOSE" != "" ] && $VERBOSE; then
                build
            else
                build &> /dev/null
            fi
        fi

        if [ $? != 0 ]; then
            print_error "An error occured during the build process. Please check the logs."
            exit 1
        fi

        DEPS=()
        if [ "$INSTALLED_PACKAGES_DIR" != "" ]; then
            read_elf_deps
        fi
        
        pack
        cd $BASEDIR
        cp $WORKDIR/$name-$version.tar.zst $BASEDIR/$name-$version.tar.zst
        checksum=$(md5sum $BASEDIR/$name-$version.tar.zst | cut -d ' ' -f 1)
        echo "$name|$version|$release|$description|$packager|$checksum|$(IFS=,; printf '%s' "${DEPS[*]}")" > .PKGINDEX
        rm -rf $WORKDIR
        ;;
esac
