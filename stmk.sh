#!/bin/bash

#################### STMK ####################
# Build/make system of Stock Linux distro    #
# License: GNU GENERAL PUBLIC LICENSE v3     #
##############################################

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
        source=(http://downloads.nutyx.org/x86_64/rolling/base/acl/acl1626618727x86_64.cards.tar.xz http://downloads.nutyx.org/x86_64/rolling/base/attr/attr1626618688x86_64.cards.tar.xz#attr.tar.xz)
        cd $WORKDIR
        for sourceURL in ${source[@]};
        do
            URL=$(echo ${sourceURL} | cut -d "#" -f 1)
            if [ $(echo ${sourceURL} | cut -d "#" -f 2) == $URL ]; then
                FILENAME=${sourceURL##*/}
            else
                FILENAME=$(echo ${sourceURL} | cut -d "#" -f 2)
            fi

            echo $URL
            echo $FILENAME
            echo ""
            curl -o $FILENAME $URL
        done
        ;;
esac
