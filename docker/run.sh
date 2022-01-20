#!/bin/bash -e

for i in "$@"
do
    case $i in
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
    esac
done
TIME=`date '+%F-%H-%M-%S'`
if [[ "$VERSION" = "jdk8u" ]]; then
    CONFIG_PARAMS="--with-milestone=${VERSION_PRE} --disable-debug-symbols --disable-zip-debug-info"
    PACKAGE_NAME="openjdk-1.8.0-${VERSION_PRE}"
else
    CONFIG_PARAMS="--with-version-opt=$TIME --with-version-pre=${VERSION_PRE} --disable-warnings-as-errors"
    PACKAGE_NAME="openjdk-${VERSION:3}-${VERSION_PRE}"
fi

echo "BUILDING"
echo "VERSION= ${VERSION}"
echo "PACKAGE= ${PACKAGE_NAME}"

mkdir $PACKAGE_NAME

pushd /build > /dev/null
if [[ $CLEAN = 1 ]]; then
    make clean
fi
bash configure -q $CONFIG_PARAMS --with-native-debug-symbols=none --prefix=/$PACKAGE_NAME/usr/lib/
make images

if [[ $NO_PACK = 1 ]]; then
    exit 0
fi

make install

popd > /dev/null

rm -rf $PACKAGE_NAME/usr/lib/bin
# Rename the built folder to $PACKAGE_NAME
mv $PACKAGE_NAME/usr/lib/jvm/* $PACKAGE_NAME/usr/lib/jvm/$PACKAGE_NAME
cp -r /DEBIAN $PACKAGE_NAME
sed -i "s#{source}#openjdk-${VERSION:3:2}#g" `find $PACKAGE_NAME/DEBIAN -type f`
sed -i "s#{package_name}#$PACKAGE_NAME#g" `find $PACKAGE_NAME/DEBIAN -type f`
sed -i "s#{priority}#${VERSION:3:2}#g" `find $PACKAGE_NAME/DEBIAN -type f`
sed -i "s#{maintainer_name}#${MAINTAINER_NAME}#g" `find $PACKAGE_NAME/DEBIAN -type f`
sed -i "s#{maintainer_email}#${MAINTAINER_EMAIL}#g" `find $PACKAGE_NAME/DEBIAN -type f`
sed -i "s#{version}#${VERSION:3:2}.0#g" `find $PACKAGE_NAME/DEBIAN -type f`
SIZE=`du -shk $PACKAGE_NAME/usr/lib/jvm/$PACKAGE_NAME | awk '{print $1}'`
sed -i "s#{size}#${SIZE}#g" `find $PACKAGE_NAME/DEBIAN -type f`
REMOTE_URL=`git -C /build remote get-url --all origin`
sed -i "s#{remote_url}#$REMOTE_URL#g" `find $PACKAGE_NAME/DEBIAN -type f`
COMMIT_HASH=`git -C /build rev-parse --short HEAD`
sed -i "s#{commit}#$COMMIT_HASH#g" `find $PACKAGE_NAME/DEBIAN -type f`

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
