#!/bin/bash

###################### HAZEL #####################
# Package builder for Stock Linux                #
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

init() {
    mkdir -p ~/hazel/sources
    mkdir -p ~/hazel/logs
    mkdir -p ~/hazel/www
    mkdir -p ~/hazel/root
}

check_env() {
    USERNAME=$(git config user.name)
    if [ ! -d ~/hazel ]; then
        print_info "Initializing hazel..."
        init
        print_success "Done !"
    fi

    if [ ! -f /bin/curl ] && [ ! -f /usr/bin/curl ]; then
        print_error "You must install curl..."
        exit 1
    fi
    
    if [ ! -f /bin/squirrel ] && [ ! -f /usr/bin/squirrel ]; then
        print_error "You must install squirrel..."
        exit 1
    fi
    
    if [ ! -d .git ]; then
        print_error "You're not in a git repo !"
        exit 1
    fi

    if [ "$USERNAME" == "" ]; then
        print_error "Your git username is not defined ! Please review your git config."
        exit 1
    fi
}

print_help() {
    echo "Usage:"
    echo ""
    print_success "hazel"
    echo -e "\t <package|directory> [version]\t Builds a specific package or a whole directory containing multiple packages."
    print_info "\t new | -n\e[0m <path> <version> <source> <description> Creates a new package at the specified path and with the specified version."
    print_info "\t build-index\e[0m\t\t\t Builds an INDEX of the current directory."
    print_info "\t help\e[0m\t\t\t\t Shows this menu."
}

build_index() {
    rm -f INDEX
    for file in $(find -iname "*.tar.zst"); do
        PACKAGE_NAME=$(cat $(dirname $file)/.PKGINDEX | cut -d '|' -f 1)
        PACKAGE_VERSION=$(cat $(dirname $file)/.PKGINDEX | cut -d '|' -f 2)
        PACKAGE_RELEASE=$(cat $(dirname $file)/.PKGINDEX | cut -d '|' -f 3)
        echo "$PACKAGE_NAME $PACKAGE_VERSION $PACKAGE_RELEASE $file" >> INDEX
    done
    for file in $(find -maxdepth 1 -iname "*.txt"); do
        echo "$(basename $file .txt)" >> INDEX
    done
}

if [ "$CONF_PATH" == "" ]; then
    CONF_PATH=/etc/squirrel.conf
fi

case $1 in
    help|-h|--help)
        print_help
        ;;

    build-index)
        build_index
        ;;

    new|-n)
        if [ "$2" == "" ] || [ "$3" == "" ] || [ "$4" == "" ] || [ "$5" == "" ]; then
            print_help
            exit
        fi

        if [ "$EDITOR" == "" ]; then
            print_error "The EDITOR variable should be defined."
            exit 1
        fi

        check_env

        mkdir -p $(dirname $2)
        cd $(dirname $2)

        PACKAGER=$USERNAME stmk c $(basename $2) $3 $4 ${@:5}

        eval "$EDITOR $(basename $2)/recipe"
        ;;

    *)
        if [ "$1" == "" ]; then
            print_help
            exit
        fi

        check_env
        
        PACKAGE_DIR_PATH=""
        for dir in $(find -type d); do
            if [[ "$dir" == *"/$1" ]]; then
                PACKAGE_DIR_PATH=$dir
            fi
        done

        if [ "$PACKAGE_DIR_PATH" == "" ]; then
            print_error "Package '$1' not found !"
            exit 1
        fi
        print_info "Pulling changes from remote repo."
        [ -f .PKGINDEX ] && sudo rm .PKGINDEX
        git pull --rebase
        print_info "Cleaning up build root directory..."
        USERDIR=$HOME
        sudo rm -rf $USERDIR/hazel/root/*
        print_success "Done !"
        echo ""
        print_info "Setting up chroot..."
        echo ""
        sudo CONF_PATH=$CONF_PATH ROOT=$USERDIR/hazel/root squirrel sync
        sudo CONF_PATH=$CONF_PATH ROOT=$USERDIR/hazel/root squirrel install core
        echo ""
        print_success "Chroot successfully created !"
        echo ""
        print_info "Downloading package sources..."
        source $PACKAGE_DIR_PATH/recipe
        if [ "$2" != "" ]; then
            sed -i "s/version=$version/version=$2/" $PACKAGE_DIR_PATH/recipe
        fi
        sed -i "s/packager=$packager/packager=$USERNAME/" $PACKAGE_DIR_PATH/recipe
        source $PACKAGE_DIR_PATH/recipe
        echo ""
        sudo mkdir -p $USERDIR/hazel/root/{sources,build}
        for sourceInfo in ${source[@]}; do
            if [ -f $sourceInfo ]; then
                cp $sourceInfo $USERDIR/hazel/sources/
                continue
            fi
            URL=$(echo $sourceInfo | cut -d '#' -f 1)
            FILENAME=$(echo $sourceInfo | cut -d '#' -f 2)
            if [ "$URL" == "$FILENAME" ]; then
                FILENAME=$(basename $URL)
            fi
            if [ -f $USERDIR/hazel/sources/$FILENAME ]; then
                continue
            fi
            if [ -f $PACKAGE_DIR_PATH/$FILENAME ]; then
                cp $PACKAGE_DIR_PATH/$FILENAME $USERDIR/hazel/sources/$FILENAME
                continue
            fi
            print_info "Downloading $FILENAME..."
            sudo curl --progress-bar -L -s -o $USERDIR/hazel/sources/$FILENAME $URL
            if [ $? != 0 ]; then
                print_error "An error occured during the download ! Exiting..."
                if [ -f $USERDIR/hazel/sources/$FILENAME ]; then
                    rm $USERDIR/hazel/sources/$FILENAME
                fi
                exit 1
            fi
            print_success "Done !"
        done

        echo ""

        sudo cp $PACKAGE_DIR_PATH/* $USERDIR/hazel/root/build
        sudo cp $USERDIR/hazel/sources/* $USERDIR/hazel/root/sources

        if [ "$makedepends" != "" ]; then
            print_info "Installing build-time dependencies..."
            for makedep in ${makedepends[@]}; do
                sudo CONF_PATH=$CONF_PATH ROOT=$USERDIR/hazel/root squirrel install $makedep
            done
        fi

        print_info "Starting build... Don't worry, it can take some time."
        sudo mount --bind /dev $USERDIR/hazel/root/dev
        sudo mount --bind /dev/pts $USERDIR/hazel/root/dev/pts
        sudo mount -t proc proc $USERDIR/hazel/root/proc
        sudo mount -t sysfs sysfs $USERDIR/hazel/root/sys
        sudo mount -t tmpfs tmpfs $USERDIR/hazel/root/run

        cat << EOF | sudo chroot $USERDIR/hazel/root &> /dev/null
cd build
print_error() {
    echo -e "\e[1;31m\$1\e[0m"
}
SOURCES_DIR=/sources VERBOSE=true JOBS=$JOBS stmk &> build.log
if [ \$? != 0 ]; then
    print_error "There was an error during the build. Check the logs !"
fi
EOF

        sudo mountpoint -q $USERDIR/hazel/root/dev/shm && sudo umount $USERDIR/hazel/root/dev/shm
        sudo umount $USERDIR/hazel/root/dev/pts
        sudo umount $USERDIR/hazel/root/{sys,proc,run,dev}

        if [ -f $USERDIR/hazel/root/build/$name-$version.tar.zst ]; then
            print_success "Done !"
            echo ""
            mkdir -p $USERDIR/hazel/www/$PACKAGE_DIR_PATH
            sudo mv $USERDIR/hazel/root/build/build.log $USERDIR/hazel/logs/$name-$version.log
            BASEDIR=$PWD
            rm $USERDIR/hazel/www/$PACKAGE_DIR_PATH/*
            cp $USERDIR/hazel/root/build/* $USERDIR/hazel/www/$PACKAGE_DIR_PATH/
            cp $USERDIR/hazel/root/build/.PKGINDEX $USERDIR/hazel/www/$PACKAGE_DIR_PATH/.PKGINDEX
            cd $USERDIR/hazel/www/
            build_index
            cd $BASEDIR
            read -p 'Do you want to commit ? (Y/n) ' COMMIT
            if [ "$COMMIT" == "Y" ] || [ "$COMMIT" == "y" ]; then
                git add $PACKAGE_DIR_PATH
                git commit -m "$name $version-$release"    
            fi
        else
            sudo cp $USERDIR/hazel/root/build/build.log $USERDIR/hazel/logs/$name-$version.log
            exit 1
        fi
        ;;
esac