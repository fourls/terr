#!/bin/bash

i=1;

platform=Linux

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


TERRARIA_VERSION=1449
SERVER_DOWNLOAD_URL=https://terraria.org/api/download/pc-dedicated-server/terraria-server-${TERRARIA_VERSION}.zip
zip_subpath=${TERRARIA_VERSION}/${platform}

# prerequisites
echo "Installing prerequisites..."
if [ "$platform" == Linux ]; then
    apt-get install -y curl unzip
elif [ "$platform" == Mac ]; then
    brew install unzip # curl should already be installed
fi

mkdir working

echo "Downloading Terraria server..."
curl -o working/terraria.zip -L $SERVER_DOWNLOAD_URL
unzip -o "working/terraria.zip" "${zip_subpath}/*" -d working/srv

rm -rf server
mkdir server
mv -f "working/srv/${zip_subpath}" server/files
echo "Server downloaded to ./server/files"

exe_path="TerrariaServer"
if [ "$platform" == Mac ]; then
    exe_path="Terraria Server.app/Contents/MacOS/TerrariaServer.bin.osx"
fi

# shellcheck disable=SC2005
echo "$(cat <<EOF
#!/bin/bash
server_dir=\$( dirname -- "\${BASH_SOURCE[0]}" )
"\${server_dir}/files/${exe_path}" "\$@"
EOF
)" > server/launch.sh
chmod u+x server/launch.sh
chmod u+x "server/files/${exe_path}"

rm -rf working