#!/bin/bash

source env.sh
export SCRIPT_DIR="$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)"

DATA_PATH=$SCRIPT_DIR/data
if [ ! -f "$DATA_PATH" ]; then
    mkdir $DATA_PATH
fi

WORLD_PATH=$DATA_PATH/worlds
WORLD_FILE="$WORLD_PATH/$TERRARIA_WORLD.wld"
CONFIG_PATH="$DATA_PATH/config.txt"

echo """
worldpath=$WORLD_PATH
motd=$TERRARIA_MOTD
password=$TERRARIA_PASSWORD
players=$TERRARIA_PLAYERS
world=$WORLD_FILE
worldname=$TERRARIA_WORLD
autocreate=1
""" > "$CONFIG_PATH"

server/TerrariaServer -config "$CONFIG_PATH"