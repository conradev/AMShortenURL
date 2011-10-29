#!/bin/bash

# Code modified from ashikase's Backgrounder get_requirements.sh script (No apparent license either)
# https://github.com/ashikase/Backgrounder

# Either wget or curl is needed to download package list and ldid.
WGET=$(type -P wget)
CURL=$(type -P curl)
if [ -z "$WGET" -a -z "$CURL" ]; then
    echo "ERROR: get_gdata.sh requires either 'wget' or 'curl' to be installed."
    exit 1
fi

# Download GData framework
echo "Downloading GData framework..."
GDATA_REPO="http://apt.thebigboss.org/repofiles/cydia"
pkg=""
if [ ! -z "$WGET" ]; then
    wget -q "${GDATA_REPO}/dists/stable/main/binary-iphoneos-arm/Packages.bz2"
    pkg_path=$(bzcat Packages.bz2 | grep "debs2.0/gdata" | awk '{print $2}')
    pkg=$(basename $pkg_path)
    wget -q "${GDATA_REPO}/${pkg_path}"
else
    curl -s -L "${GDATA_REPO}/dists/stable/main/binary-iphoneos-arm/Packages.bz2" > Packages.bz2
    pkg_path=$(bzcat Packages.bz2 | grep "debs2.0/gdata" | awk '{print $2}')
    pkg=$(basename $pkg_path)
    curl -s -L "${GDATA_REPO}/${pkg_path}" > $pkg
fi
ar -p $pkg data.tar.gz | tar -xvf - &> /dev/null
if [ -e ./External/GData.framework ]; then
    rm -r ./External/GData.framework
fi
mv ./System/Library/Frameworks/GData.framework ./External/
rm -rf System Packages.bz2 $pkg
