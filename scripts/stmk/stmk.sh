#!/bin/bash

#################### STMK ####################
# Build/make system of Stock Linux distro    #
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
        ERROR=true
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
    echo "Package information:"
    echo ""
    echo "Package name: $name"
    echo "Package version: $version"
    echo "Package description: $description"
    echo ""
    echo "Workdir: $WORKDIR"
    echo ""
}

print_warning() {
    echo -e "\e[1;33m$1\e[0m"
}

unpack() {
    pkgname=$name
    if [[ "$name" == "lib32"* ]]; then
        pkgname=${name//"lib32-"/}
    fi
    tar -xf $pkgname-$version.tar.*
    if [ -d $pkgname-$version ]; then
        cd $pkgname-$version
    fi
}

build() {
    if [[ "$name" == "lib32"* ]]; then
        CFLAGS+=" -m32" CXXFLAGS+=" -m32" \
        ./configure --prefix=/usr \
            --libdir=/usr/lib32 --disable-static || CFLAGS+=" -m32" CXXFLAGS+=" -m32" ./configure --prefix=/usr --libdir=/usr/lib32
        make
        make DESTDIR=$PWD/DESTDIR install
        mkdir -p $PKG/usr/lib32
        cp -Rv DESTDIR/usr/lib32/* $PKG/usr/lib32
        rm -rf DESTDIR
    else
        ./configure --prefix=/usr --disable-static || ./configure --prefix=/usr
        make
        make DESTDIR=$PKG install
    fi
}

build_python() {
    PYTHONPATH=src pip3 wheel -w dist --no-build-isolation --no-deps $PWD
    pip3 install --root=$PKG --no-index --find-links=dist $name
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
    echo "$name|$version|$release|$description|$packager|$checksum|$(IFS=,; printf '%s' "${DEPS[*]}")" > .PKGINDEX
    tar -I 'zstd --ultra -22' -cf ../$name-$version.tar.zst .
}

strip_files() {
    cd $PKG
    for file in $(find);
    do
        case $(file -b "$file") in
            *ELF*executable*not\ stripped)
                strip --strip-all "$file"
                ;;
            *ELF*shared\ object*not\ stripped)
                strip --strip-unneeded "$file"
                ;;
            current\ ar\ archive)
                strip --strip-debug "$file"
        esac
    done
}

read_elf_deps() {
    cd $PKG
    DEPS=()
    for file in $(find);
    do
        FILETYPE=$(file $file | cut -d ' ' -f 2)
        if [ "$FILETYPE" == "ELF" ]; then
            ARCH=$(file $file | cut -d ' ' -f 3)
            LIBRARIES=$(readelf -d $file | grep 'NEEDED' | cut -d ':' -f 2 | cut -d '[' -f 2 | cut -d ']' -f 1)
            for library in $LIBRARIES; do
                for package in /var/packages/*;
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

pre_build() {
    return 0
}

post_build() {
    return 0
}

# CLI parser
case "$1" in
    "c"|"create")
	mkdir $2
	all_args=("$@")
	cat > $2/recipe <<EOF
name=$2
version=$3
release=1
description="${all_args[@]:4}"
source=($(echo $4 | sed "s/$3/\$version/g" | sed "s/$2/\$name/g"))
packager=$PACKAGER
EOF
        ;;
    *)
        BASEDIR=$PWD
        source ./recipe
        WORKDIR=$(mktemp -d)
        SRC=$WORKDIR/src
        mkdir $SRC
        cd $SRC
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

            if [ "$SOURCES_DIR" == "" ]; then
                if [ ! -f $BASEDIR/$FILENAME ]; then
                    curl -L -o $FILENAME $URL
                else
                    cp $BASEDIR/$FILENAME .
                fi
            else
                cp $SOURCES_DIR/$FILENAME .
            fi
        done            

        echo ""

        PKG=$WORKDIR/dist
        mkdir $PKG

        unpack
        pre_build
        if [ "$JOBS" != "" ]; then
            export MAKEFLAGS="-j$JOBS"
            export NINJAJOBS=$JOBS
        fi

        if [ "$VERBOSE" != "" ] && $VERBOSE; then
            build
            if [ $? != 0 ]; then
                print_error "An error occured during the build process. Please check the logs."
                exit 1
            fi
            post_build
            if [ $? != 0 ]; then
                print_error "An error occured during the post-build process. Please check the logs."
                exit 1
            fi
        else
            build &> /dev/null
            if [ $? != 0 ]; then
                print_error "An error occured during the build process. Please check the logs."
                exit 1
            fi
            post_build &> /dev/null
            if [ $? != 0 ]; then
                print_error "An error occured during the post-build process. Please check the logs."
                exit 1
            fi
        fi

        DEPS=()
        read_elf_deps

        if [ "$run" != "" ]; then
            DEPS+=(${run[@]})
        fi
        
        if [ "$NO_STRIP" == "" ]; then
            strip_files
        fi
        
        if [ -f $BASEDIR/post-install ]; then
            cp $BASEDIR/post-install $PKG/.post-install
        fi
        
        pack
        cd $BASEDIR
        cp $WORKDIR/$name-$version.tar.zst $BASEDIR/$name-$version.tar.zst
        checksum=$(md5sum $BASEDIR/$name-$version.tar.zst | cut -d ' ' -f 1)
        echo "$name|$version|$release|$description|$packager|$checksum|$(IFS=,; printf '%s' "${DEPS[*]}")" > .PKGINDEX
        rm -rf $WORKDIR
        ;;
esac
