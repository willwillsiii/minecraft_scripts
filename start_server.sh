#!/bin/bash

if [ "$#" -gt 1 ]; then
    echo "Error: More than one argument supplied."
    # TODO: Add usage info!
    exit 1
fi

if [ -n "$1" ]; then
    server_configs=$(find . -name "server.properties.*" ! -name "server.properties.bak" \
        | sed 's/.*\.//')
    if [ "$1" = "--list" ]; then
        echo "$server_configs"
        exit 0
    fi
    selected_config=$(echo "$server_configs" | fzf --query $1 --select-1)
    if [ -z "$selected_config" ]; then
        echo "None selected."
        exit 1
    fi
    echo "Backing up and switching to server.properties.$selected_config..."
    cp "server.properties" "server.properties.bak"
    cp "server.properties.$selected_config" "server.properties"
fi

java -Xms2G -Xmx2G -jar minecraft_server.1.20.4.jar nogui
