#!/bin/bash

SCRIPT_DIR="$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)"
TERRARIA_VERSION=1449
DOWNLOAD_URL=https://terraria.org/api/download/pc-dedicated-server/terraria-server-${TERRARIA_VERSION}.zip

platform=Linux

i=1;
while [ $i -le $# ]; do
    case $1 in
        --platform)
            if [ ! $i -lt $# ]; then
                echo "error: no value for --platform"
                exit 1
            fi

            case $2 in
                mac) platform=Mac;;
                linux) platform=Linux;;
                *) echo "error: unknown value for --platform" && exit 1;;
            esac
    esac

    i=$((i + 1));
    shift 1;
done

# prerequisites
echo "Installing prerequisites..."
if [ "$platform" == Linux ]; then
    apt-get install -y curl unzip
elif [ "$platform" == Mac ]; then
    brew install unzip # curl should already be installed
fi

mkdir working

echo "Downloading Terraria server..."
zip_subpath=${TERRARIA_VERSION}/${platform}
curl -o working/terraria.zip -L $DOWNLOAD_URL
unzip -o "working/terraria.zip" "${zip_subpath}/*" -d working/srv

rm -rf server
mkdir server
mv -f "working/srv/${zip_subpath}" server/files
echo "Server downloaded to ./server/files"

exe_path="TerrariaServer"
if [ "$platform" == Mac ]; then
    exe_path="Terraria Server.app/Contents/MacOS/TerrariaServer.bin.osx"
fi
exe_path=$SCRIPT_DIR/server/files/$exe_path

chmod u+x "$exe_path"
echo "$exe_path" > server/launch.txt
echo "Configured executable at $exe_path"

rm -rf working