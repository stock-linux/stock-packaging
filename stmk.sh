#!/bin/bash

#################### STMK ####################
# Build/make system of Stock Linux distro    #
# License: GNU GENERAL PUBLIC LICENSE v3     #
##############################################

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

    if [ "$depends" == "" ]; then
        if $ERROR; then
            echo ""
        fi
        print_warning "No compilation dependencies."
        echo ""
    fi

    if $ERROR ; then
        exit 1
    fi
}

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

print_error() {
    echo -e "\e[1;31m$1\e[0m"
}

print_variables() {
    print_header "Package information:"
    print_content ""
    print_content "Package name: $name"
    print_content "Package version: $version"
    print_content "Package description: $description"
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
    ./configure --prefix=/usr --disable-static
    make
    make DESTDIR=$PKG install
}

pack() {
    cd $PKG
    # Remove unneeded and harmful LA files
    if [ $KEEP_LA==true ]; then
        for file in $(find $directory -type f -name "*.la");
        do
            echo $file
        done
    fi

    tar -I 'zstd --ultra -22' -cf ../$name-$version.tar.zst $PKG
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
        source ./recipe
        WORKDIR=$(mktemp -d)
        cd $WORKDIR
        # Check the presence of needed variables
        check_variables

        # Print package information
        print_variables

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
        ;;
esac
