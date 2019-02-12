#!/bin/bash -e

if [[ "$VERSION" = "jdk8u" ]]; then
    CONFIG_PARAMS=""
elif [[ "$VERSION" = "jdk11" ]]; then
    TIME=`date '+%F-%H-%M-%S'`
    CONFIG_PARAMS="--with-version-opt=$TIME --disable-warnings-as-errors"
elif [[ "$VERSION" = "jdk12" ]]; then
    TIME=`date '+%F-%H-%M-%S'`
    CONFIG_PARAMS="--with-version-opt=$TIME --disable-warnings-as-errors"
else
    echo "The version $VERSION is not in the run.sh script."
    exit 1
fi

cd /build

bash configure -q $CONFIG_PARAMS --disable-zip-debug-info --prefix=/install/usr/lib/
if [[ "$1" = "--clean" ]]; then
    make clean
fi
make images
make install

cd /install
rm -rf usr/lib/bin
zip jdk_$VERSION.zip usr/ -r
mv jdk_$VERSION.zip /build/
