#!/bin/bash

CLEAN=0
NO_TEST=0
NO_PACK=0
CHOWN=0

while [[ $# -gt 0 ]]; do
    case $1 in
        --clean)
        CLEAN=1
        shift
        ;;
        --no-test)
        NO_TEST=1
        shift
        ;;
        --no-pack)
        NO_PACK=1
        shift
        ;;
        --chown)
        CHOWN=1
        shift
        ;;
        --tag)
        CO_TAG="$2"
        shift
        shift
        ;;
        *)
        shift
        ;;
    esac
done

if [ -z $CO_TAG ]; then
  echo "--tag <TAG> is a required parameter"
  exit 1
fi

TIME=$(date '+%FT%H-%M-%S')
# Include version number in TAG if it does not contain it
if [[ "$VERSION" == "jdk8u" ]]; then
    CONFIG_PARAMS="--with-milestone=${VERSION_PRE} --disable-debug-symbols --disable-zip-debug-info"
else
    CONFIG_PARAMS="--with-version-opt=$TIME --with-version-pre=${VERSION_PRE} --disable-warnings-as-errors"
fi
if [[ $CO_TAG == *jdk-"${VERSION:3:2}"* ]]; then
    TAG=$CO_TAG
else
    TAG="${VERSION:3:2}-$CO_TAG"
fi
PACKAGE_NAME="openjdk-${TAG}-${VERSION_PRE}"
BUILD_VERSION="$(echo ${CO_TAG} | tr -dc [0-9.+])"
if [ -z "$BUILD_VERSION" ]; then
  BUILD_VERSION="$TAG"
fi
echo ""
echo "-- BUILDING --"
echo "-- CLEAN   = ${CLEAN}"
echo "-- NO_TEST = ${NO_TEST}"
echo "-- NO_PACK = ${NO_PACK}"
echo "-- SOURCE_VERSION = ${VERSION}"
echo "-- BUILD_VERSION = ${BUILD_VERSION}"
echo "-- PACKAGE = ${PACKAGE_NAME}"
echo "-- TIME    = ${TIME}"
echo "-- TAG     = ${TAG}"


pushd /build > /dev/null
git config --global --add safe.directory /build
if [[ $CLEAN = 1 ]]; then
    git clean -xdff
fi
echo ""
echo "Checking out tag ${CO_TAG}"
git -c advice.detachedHead=false checkout ${CO_TAG}
bash configure $CONFIG_PARAMS --with-native-debug-symbols=none
make images

if [[ $NO_PACK = 1 ]]; then
    exit 0
fi

popd > /dev/null

PACKAGE_PRIORITY=$(./version_to_priority.py ${CO_TAG})
# Rename the built folder to $PACKAGE_NAME
mkdir -p /$PACKAGE_NAME/usr/lib/jvm/$PACKAGE_NAME
mv /build/build/*/images/jdk/* /$PACKAGE_NAME/usr/lib/jvm/$PACKAGE_NAME
cp -r /DEBIAN $PACKAGE_NAME
sed -i "s#{source}#openjdk-${VERSION:3:2}#g" `find $PACKAGE_NAME/DEBIAN -type f`
sed -i "s#{package_name}#$PACKAGE_NAME#g" `find $PACKAGE_NAME/DEBIAN -type f`
sed -i "s#{priority}#${PACKAGE_PRIORITY}#g" `find $PACKAGE_NAME/DEBIAN -type f`
sed -i "s#{maintainer_name}#${MAINTAINER_NAME}#g" `find $PACKAGE_NAME/DEBIAN -type f`
sed -i "s#{maintainer_email}#${MAINTAINER_EMAIL}#g" `find $PACKAGE_NAME/DEBIAN -type f`
sed -i "s#{version}#${BUILD_VERSION}#g" `find $PACKAGE_NAME/DEBIAN -type f`
SIZE=`du -shk $PACKAGE_NAME/usr/lib/jvm/$PACKAGE_NAME | awk '{print $1}'`
sed -i "s#{size}#${SIZE}#g" `find $PACKAGE_NAME/DEBIAN -type f`
REMOTE_URL=`git -C /build remote get-url --all origin`
sed -i "s#{remote_url}#$REMOTE_URL#g" `find $PACKAGE_NAME/DEBIAN -type f`
COMMIT_HASH=`git -C /build rev-parse --short HEAD`
sed -i "s#{commit}#$COMMIT_HASH#g" `find $PACKAGE_NAME/DEBIAN -type f`
COMMIT_DATE=`git -C /build show -s --format=%ci $COMMIT_HASH`
sed -i "s#{commit_date}#$COMMIT_DATE#g" `find $PACKAGE_NAME/DEBIAN -type f`
sed -i "s#{current_time}#$TIME#g" `find $PACKAGE_NAME/DEBIAN -type f`


echo ""
echo "Building the following deb package:"
cat $PACKAGE_NAME/DEBIAN/control

dpkg-deb --build $PACKAGE_NAME

if [[ $NO_TEST != 1 ]]; then

    # Test the package
    echo ""
    echo "-----"
    echo "Install and verify $PACKAGE_NAME"
    echo "-----"
    echo ""

    apt-get install -y ./$PACKAGE_NAME.deb &> /tmp/install.log
    if [[ "$?" != "0" ]]; then
        echo "Error:"
        cat /tmp/install.log
        exit 1
    else
        echo "Package $PACKAGE_NAME.deb installs successfully"
        echo "The current java version is:"
        java -version
    fi

    if grep update-alternatives /tmp/install.log &> /dev/null
    then
        echo "Package $PACKAGE_NAME.deb seems to be correctly configured."
    else
        echo "ERROR: Package $PACKAGE_NAME.deb does not configure correctly. See \"postinst\" script in debconf folder."
        cat /tmp/install.log
        exit 1
    fi

    echo ""
    echo "-----"
    echo ""

    apt-get purge -y $PACKAGE_NAME &> /tmp/uninstall.log
    if [[ "$?" != "0" ]]; then
        echo "ERROR:"
        cat /tmp/uninstall.log
        exit 1
    else
        echo "Package $PACKAGE_NAME.deb uninstalls successfully"
        echo "The current java version is:"
        java -version
    fi

    if grep update-alternatives /tmp/uninstall.log &> /dev/null
    then
        echo "Package $PACKAGE_NAME.deb seems to be correctly de-configured."
    else
        echo "ERROR: Package $PACKAGE_NAME.deb is not deconfigured corectly. See \"prerm\" script in debconf folder."
        cat /tmp/install.log
        exit 1
    fi
fi

mv $PACKAGE_NAME.deb /packages/

if [[ $CHOWN = 1 ]]; then
  echo ""
  echo "Changing owner of build artifacts to local user"
  chown user:user -R /build/
  chown user:user /packages/$PACKAGE_NAME.deb
fi
