#!/bin/bash

me=$(basename "$0")

for arg in "$@"; do
    if [[ $arg =~ (-h|--help) ]]; then

        echo "Usage: $me [OPTION]"
        echo "Backs up the current world,"
        echo "then creates a new one after changing server settings."
        echo
        echo "Options:"
        echo "    -h, --help    displays this"
        echo "    -n name       create new world using name"
        echo "    -b [name]     backup using name (leave empty for none)"
        echo "    -B            only backup, do nothing else"
        echo "    -d            leave out date in backup"
        echo "    -c            don't compress the backup"
        echo "    -r            don't run the server"

        exit

    fi
done

backup=true
only_backup=false
use_date=true
compress=true
run=true

while [[ $# > 0 ]]; do
    case "$1" in

        -n) if [[ -z $2 || $2 =~ (-b|-B|-d|-c|-r) ]]; then
                echo "No name supplied to -n: use '$me --help' for more info."
                exit 1
            fi
            new_name=$2
            shift
            ;;

        -B) if [[ $backup = false ]]; then
                echo "Must supply a name to use -b with -B:"
                echo "Use '$me --help' for more info."
                exit 1
            fi
            only_backup=true
            run=false
            ;;

        -b) if [[ ! -z $2 && ! $2 =~ (-n|-B|-d|-c|-r) ]]; then
                backup_name=$2
                shift
            elif [[ $only_backup = true ]]; then
                echo "Must supply a name to use -b with -B:"
                echo "Use '$me --help' for more info."
                exit 1
            else
                backup=false
            fi
            ;;

        -d) use_date=false
            ;;

        -c) compress=false
            ;;

        -r) run=false
            ;;

    esac
    shift
done

old_world=$(awk -F '=' '/^level-name/ {print $2}' server.properties)
# if [[ -z $new_name ]]; then
#     new_name=$old_world
# fi
old_view=$(awk -F '=' '/^view-distance/ {print $2}' server.properties)

if [[ $backup = true && ! -d $old_world ]]; then
    echo "Current world $old_world not found!"
    echo "Can't back it up."
    backup=false
fi

if [[ $backup = true ]]; then
    if [[ -z $backup_name ]]; then
        backup_name=$old_world
    fi
    if [[ $use_date = true ]]; then
        backup_name=${backup_name}_$(date +%Y_%m_%d_%Hh%Mm%Ss_%Z)
    fi
    if [[ $compress = true ]]; then
        backup_name=$backup_name.tar.gz
        echo "Compressing and backing up $old_world to $backup_name ..."
        tar -zcf old_worlds/$backup_name $old_world*/ && \
        echo "Compressing and backing up complete!"
        if [[ $only_backup = false ]]; then
            echo "Deleting $old_world ..."
            rm -rf $old_world* && \
            echo "Deleting $old_world completed!"
        fi
    else
        echo "Moving $old_world to old_worlds/$backup_name ..."
        mkdir old_worlds/$backup_name
        mv $old_world* old_worlds/$backup_name && \
        echo "Backing up complete!"
    fi
elif [[ -d $old_world ]]; then
    echo "No backup name was supplied, and the files will be deleted."
    read -p "Are you sure you want to delete $old_world? (yes/no): " -r
    if [[ $REPLY =~ (Yes|yes|Y|y) ]]; then
        echo "Deleting $old_world ..."
        rm -rf $old_world* && \
        echo "Deleting $old_world completed!"
    else
        echo "Exiting ..."
        exit 1
    fi
fi

if [[ ! -z $new_name ]]; then
    echo "Changing world name to $new_name ..."
    sed -i "s/^level-name=.*/level-name=$new_name/" \
        server.properties && \
    echo "Changing world name to $new_name complete!"
    current_world=$new_name
else
    current_world=$old_world
fi

if [[ $run = true ]]; then
    echo "Running the server ..."
    # set -x
    ./start_server.sh <<< 'stop' && \
    # set +x && \
    echo "Running the server complete!"
    echo "Modifying world permissions..."
    chmod -R go-w "$current_world" &&\
    echo "Modiyfing world permissions complete!"
fi
