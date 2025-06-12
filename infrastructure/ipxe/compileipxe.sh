#!/usr/bin/env bash

CONF=$(pwd)/ipxe/src/config
SRC=$(pwd)/ipxe/src

# Install compiler and dependencies
#sudo apt-get install -y git gcc make liblzma-dev

# Grab the source code
git clone https://github.com/ipxe/ipxe.git

cp "general.h" "${SRC}/config/general.h"

cd "$SRC" || exit

curl -SsL -o cacert.pem --etag-compare etag.txt --etag-save etag.txt --remote-name https://curl.se/ca/cacert.pem

#cat <<EOF > embed.ipxe
#!ipxe
#boot
#EOF



# Make bin-x86_64-linux/ipxe.pxe
make bin-x86_64-efi/snponly.efi bin-x86_64-efi/ipxe.efi CERT=cacert.pem TRUST=cacert.pem #bin-x86_64-pcbios/undionly.kpxe #EMBED=embed.ipxe 

cd - || exit

# Copy ipxe.efi to local dir
cp "$SRC"/bin-x86_64-efi/snponly.efi .
cp "$SRC"/bin-x86_64-efi/ipxe.efi .
#cp "$SRC"/bin-x86_64-pcbios/undionly.kpxe .
