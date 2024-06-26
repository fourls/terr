#!/bin/bash

if [ $# -lt 1 ]; then
    echo "usage: terraria.sh [ install | config | choose | run ]"
    exit 1
fi

UNAME=$(uname)

BASEDIR=$(pwd)
SERVERFILES=${BASEDIR}/server
WORLDPATH=${BASEDIR}/worlds
CONFIG=${BASEDIR}/config.txt
case $UNAME in
    Darwin) EXE_PATH="${SERVERFILES}/Terraria Server.app/Contents/MacOS/TerrariaServer.bin.osx";;
    *) EXE_PATH="${SERVERFILES}/TerrariaServer.bin.x86_64";;
esac

function install_server {
    local version=$1
    shift

    if [ "$UNAME" == Darwin ]; then
        local platform="Mac"
        brew install unzip
    else
        local platform="Linux"
        apt-get install -y curl unzip
    fi

    mkdir working

    echo "Downloading Terraria server..."
    local zip_subpath=${version}/${platform}
    curl -o working/terraria.zip -L "https://terraria.org/api/download/pc-dedicated-server/terraria-server-${version}.zip"
    unzip -o "working/terraria.zip" "${zip_subpath}/*" -d working/srv

    rm -rf "${SERVERFILES}"
    mv -f "working/srv/${zip_subpath}" "${SERVERFILES}"
    echo "Server downloaded"

    chmod u+x "${EXE_PATH}"
    echo "Configured permissions for ${EXE_PATH}"

    configure_server -port 7777 -discard

    rm -rf working
}

function configure_server {
    while [ $# -gt 0 ]; do
        case $1 in
            -port) shift && local port=$1;;
            -password) shift && local password=$1;;
            -maxplayers) shift && local maxplayers=$1;;
            -motd) shift && local motd=$1;;
            -discard) local discard=1;;
            *) echo "Unknown install parameter '$1'; ignoring.";;
        esac

        shift
    done

    if [ -z "$discard" ]; then
        while read -r line; do
            IFS="=" read -ra split <<< "$line"
            local key="${split[0]}"
            local value="${split[1]}"

            if [ -n "$value" ]; then
                case $key in
                    port) [ -z "$port" ] && local port=$value;;
                    password) [ -z "$password" ] && local password=$value;;
                    maxplayers) [ -z "$maxplayers" ] && local maxplayers=$value;;
                    motd) [ -z "$motd" ] && local motd=$value;;
                esac
            fi
        done < "$CONFIG"
    fi

    local settings
    settings="$(cat <<EOF
# Non-configurable settings
worldpath=${WORLDPATH}
# Configurable settings
port=${port}
password=${password}
maxplayers=${maxplayers}
motd=${motd}
EOF
    )" || true

    echo "$settings"
    echo "$settings" > "$CONFIG"
}

function run_terraria {
    "$EXE_PATH" "$@"
}

function run_terraria_world {
    local worldname=$1 && shift
    local worldfile="${WORLDPATH}/${worldname}.wld"

    if [ -z "$worldname" ]; then
        echo "usage: terraria.sh run <world name>" && exit 1
    elif [ ! -f "$worldfile" ]; then
        echo "World '${worldname}' does not exist."
        exit 2
    fi

    run_terraria -config "$CONFIG" -world "$worldfile" "$@"
}

function main {
    local cmd=$1 && shift

    case $cmd in
        install) install_server "1449" "$@" ;;
        config) configure_server "$@" ;;
        choose) run_terraria -config "$CONFIG" ;;
        run) run_terraria_world "$@" ;;
        *) echo "unknown command '$cmd'" && exit 1 ;;
    esac
}

main "$@"