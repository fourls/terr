#!/bin/bash

TERRARIA_VERSION=1449
SERVER_DOWNLOAD_URL=https://terraria.org/api/download/pc-dedicated-server/terraria-server-${TERRARIA_VERSION}.zip
ZIP_SUBPATH=${TERRARIA_VERSION}/Linux

# prerequisites
echo "Installing prerequisites..."
apt-get install -y curl unzip

mkdir working

echo "Downloading Terraria server..."
curl -o working/terraria.zip -L $SERVER_DOWNLOAD_URL
unzip -o working/terraria.zip ${ZIP_SUBPATH}/* -d working/srv
chmod u+x working/srv/${ZIP_SUBPATH}/TerrariaServer*

rm -rf server
mkdir server
mv -f working/srv/${ZIP_SUBPATH}/* -t server
echo "Server downloaded to server/"

rm -rf working