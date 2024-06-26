#!/bin/bash
UNAME=$(uname)
TMUX_SESSION="terrariasrv_managed"
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
        brew install unzip tmux
    else
        local platform="Linux"
        apt-get install -y curl unzip tmux
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
    "$EXE_PATH" -config "$CONFIG" "$@"
}

function get_world_file {
    local worldname=$1
    local worldfile="${WORLDPATH}/${worldname}.wld"

    if [ -z "$worldname" ]; then
        echo "usage: Please supply a world name"
        return 1
    elif [ ! -f "$worldfile" ]; then
        echo "err: World '${worldname}' does not exist"
        return 2
    fi

    echo "$worldfile"
}

function tmux_terraria_running {
    tmux has "-t$TMUX_SESSION" &>/dev/null
    return $?
}

function start_tmux_terraria {
    if tmux_terraria_running; then
        echo "err: Terraria server is already running"
        exit 3
    fi

    local world
    if ! world=$(get_world_file "$1"); then
        echo "$world"
        exit 1
    fi
    shift

    local tmux_args=("-s${TMUX_SESSION}")
    if [ "$1" != "-j" ]; then
        tmux_args+=("-d")
    fi

    if tmux new "${tmux_args[@]}" -- "$EXE_PATH" -world "$world" "$@"; then
        echo "Terraria server session created."
    else
        echo "err: Failed to create Terraria server session"
    fi
}

function stop_tmux_terraria {
    if ! tmux_terraria_running; then
        echo "err: No Terraria server is running"
        exit 3
    fi

    if [ ! "$1" == "-f" ]; then
        echo "Terraria server should be stopped by joining and passing 'exit'. Pass -f to override this and kill the session."
        exit 4
    fi

    if tmux kill-session "-t${TMUX_SESSION}"; then
        echo "Terraria server session killed."
    else
        echo "err: Failed to kill Terraria server session"
    fi
}

function join_tmux_terraria {
    if ! tmux_terraria_running; then
        echo "err: No Terraria server is running"
        exit 3
    fi

    if ! tmux attach "-t${TMUX_SESSION}"; then
        echo "err: Failed to attach to Terraria server session"
    fi
}

function get_tmux_terraria_status {
    echo -n "Server: "
    if tmux_terraria_running; then
        echo "RUNNING"
    else
        echo "STOPPED"
    fi
}

function main {
    if [ $# -lt 1 ]; then
        echo "usage: terraria.sh [ install | config | choose | run | start | stop | join | status ]"
        exit 1
    fi

    local cmd=$1 && shift

    case $cmd in
        install) install_server "1449" "$@" ;;
        config) configure_server "$@" ;;
        choose) run_terraria "$@" ;;
        run)
            local world
            world=$(get_world_file "$1") && shift
            run_terraria -world "$world" "$@"
            ;;
        start) start_tmux_terraria "$@" ;;
        stop) stop_tmux_terraria "$@" ;;
        join) join_tmux_terraria "$@" ;;
        status) get_tmux_terraria_status ;;
        *) echo "unknown command '$cmd'" && exit 1 ;;
    esac
}

main "$@"