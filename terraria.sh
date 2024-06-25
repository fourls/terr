#!/bin/bash

if [ $# -lt 1 ]; then
    echo "usage: run.sh [ install | init | run ]"
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

function install_server() {
    local version=$1

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

    # shellcheck disable=SC2005
    echo "$(cat <<EOF
worldpath=${WORLDPATH}
password=
EOF
    )" > "$CONFIG"

    rm -rf working
}

function run_terraria() {
    "$EXE_PATH" "$@"
}

case $1 in
    install) install_server "1449" ;;
    choose) run_terraria -config "$CONFIG" ;;
    run)
        if [ -z "$2" ]; then
            echo "usage: run.sh run <world name>" && exit 1
        elif [ ! -f "${WORLDPATH}/${2}.wld" ]; then
            echo "World '${2}' does not exist."
            exit 2
        else
            run_terraria -config "$CONFIG" -world "${WORLDPATH}/${2}.wld"
        fi
    ;;
    *) echo "unknown command '$1'" && exit 1 ;;
esac