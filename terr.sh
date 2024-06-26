#!/bin/bash

# System properties
UNAME=$(uname)
TMUX_SESSION="terrariasrv_managed"

# File locations
if [ -z "$TERR_HOME" ]; then
    TERR_HOME=$(pwd)
fi
SERVERFILES=${TERR_HOME}/server
WORLDPATH=${TERR_HOME}/worlds
CONFIG=${TERR_HOME}/config.txt

case $UNAME in
    Darwin) EXE_PATH="${SERVERFILES}/Terraria Server.app/Contents/MacOS/TerrariaServer.bin.osx";;
    *) EXE_PATH="${SERVERFILES}/TerrariaServer.bin.x86_64";;
esac

function techo {
    echo "[terr] $1"
}

function install_server {
    local version=$1
    shift

    techo "Installing prerequisites..."
    if [ "$UNAME" == Darwin ]; then
        local platform="Mac"
        brew install unzip tmux || exit 1
    else
        local platform="Linux"
        apt-get install -y curl unzip tmux || exit 1
    fi
    techo "Done"

    mkdir working
    techo "Downloading Terraria server..."
    local zip_subpath=${version}/${platform}

    curl -o working/terraria.zip -L "https://terraria.org/api/download/pc-dedicated-server/terraria-server-${version}.zip" || exit 1
    unzip -o "working/terraria.zip" "${zip_subpath}/*" -d working/srv >/dev/null || exit 1

    rm -rf "${SERVERFILES}" && mkdir "${SERVERFILES}"
    mv -f working/srv/"${zip_subpath}"/* "${SERVERFILES}/" || exit 1
    chmod +x "${EXE_PATH}" || exit 1
    techo "Done"

    if [ ! -f "${CONFIG}" ]; then
        techo "Creating config file..."
        configure_server -port 7777 -discard
        techo "Done"
    else
        techo "Config file already exists"
    fi

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

function list_worlds {
    for world in "${WORLDPATH}"/*.wld; do
        basename "$world" .wld
    done
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

function help {
    echo "usage: terr <command>"
    echo
    echo "Setup commands:"
    echo "  install <args>...  Install the Terraria server and all dependencies"
    echo "                     Additional arguments get passed directly to the server"
    echo "  config             Retrieve or update the server configuration file"
    echo "    [-port <port>]"
    echo "    [-maxplayers <n>]"
    echo "    [-motd <motd>]"
    echo "    [-password <password>]"
    echo
    echo "Metadata commands:"
    echo "  home               Print the terr home directory"
    echo "  worlds             List all saved worlds"
    echo
    echo "Launch commands:"
    echo "  choose             Start the server in this terminal without loading a world"
    echo "                     Additional arguments get passed directly to the server"
    echo "  run <world>        Start the server in this terminal, loading the given world"
    echo
    echo "Advanced launch commands (using tmux):"
    echo "  start <world>      Start the server in a new tmux session, loading the given world"
    echo "  stop [-f]          Stop the server tmux session"
    echo "  join               Attach to the server tmux session"
    echo "  status             Print the status of the server tmux session"
}

function main {
    if [ $# -lt 1 ]; then
        help
        exit 1
    fi

    local cmd=$1
    shift

    case $cmd in
        help|-h|-help|--help) help ;;
        install) install_server "1449" "$@" ;;
        config) configure_server "$@" ;;
        choose) run_terraria "$@" ;;
        worlds) list_worlds "$@" ;;
        home) echo "$TERR_HOME" ;;
        run)
            local world
            world=$(get_world_file "$1") && shift
            run_terraria -world "$world" "$@"
            ;;
        start) start_tmux_terraria "$@" ;;
        stop) stop_tmux_terraria "$@" ;;
        join) join_tmux_terraria "$@" ;;
        status) get_tmux_terraria_status ;;
        *) echo "unknown command '$cmd'" && help && exit 1 ;;
    esac
}

main "$@"