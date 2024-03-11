#!/usr/bin/env bash

CONF=$(pwd)/ipxe/src/config
SRC=$(pwd)/ipxe/src

# Install compiler and dependencies
#sudo apt-get install -y git gcc make liblzma-dev

# Grab the source code
git clone https://github.com/ipxe/ipxe.git

cp "general.h" "${SRC}/config/general.h"

cd $SRC

#curl -SsL -o cacert.pem https://curl.se/ca/cacert.pem

#cat <<EOF > embed.ipxe
#!ipxe
#boot
#EOF



# Make bin-x86_64-linux/ipxe.pxe
make bin-x86_64-efi/snponly.efi bin-x86_64-efi/ipxe.efi # TRUST=cacert.pem EMBED=embed.ipxe #bin-x86_64-pcbios/undionly.kpxe 

cd -

# Copy ipxe.efi to local dir
cp $SRC/bin-x86_64-efi/snponly.efi .
cp $SRC/bin-x86_64-efi/ipxe.efi .
#cp $SRC/bin-x86_64-pcbios/undionly.kpxe .
