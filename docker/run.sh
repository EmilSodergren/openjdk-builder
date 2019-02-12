#!/bin/bash -e

if [[ "$VERSION" = "jdk8u" ]]; then
    CONFIG_PARAMS="--with-milestone=emil --disable-zip-debug-info"
    PACKAGE_NAME="openjdk-1.8.0-emil"
elif [[ "$VERSION" = "jdk11" ]]; then
    TIME=`date '+%F-%H-%M-%S'`
    CONFIG_PARAMS="--with-version-opt=$TIME --with-version-pre=emil --disable-warnings-as-errors"
    PACKAGE_NAME="openjdk-11-emil"
elif [[ "$VERSION" = "jdk12" ]]; then
    TIME=`date '+%F-%H-%M-%S'`
    CONFIG_PARAMS="--with-version-opt=$TIME --with-version-pre=emil --disable-warnings-as-errors"
    PACKAGE_NAME="openjdk-12-emil"
else
    echo "The version $VERSION is not in the run.sh script."
    exit 1
fi

mkdir $PACKAGE_NAME

pushd /build > /dev/null
bash configure -q $CONFIG_PARAMS --with-native-debug-symbols=none --prefix=/$PACKAGE_NAME/usr/lib/
if [[ "$1" = "--clean" ]]; then
    make clean
fi
make images
make install

popd > /dev/null

rm -rf $PACKAGE_NAME/usr/lib/bin
cp -r /DEBIAN $PACKAGE_NAME

dpkg-deb --build $PACKAGE_NAME

mv $PACKAGE_NAME.deb /packages/

# Test the package
echo ""
echo "-----"
echo "Install and verify $PACKAGE_NAME"
echo "-----"
echo ""

cd /packages

apt install -y ./$PACKAGE_NAME.deb &> /tmp/install.log
if [[ "$?" != "0" ]]; then
    echo "Error:"
    cat /tmp/install.log
    exit 1
else
    echo "Package $PACKAGE_NAME.deb installs sucessfully"
    echo "The current java version is:"
    java -version
fi

if grep update-alternatives /tmp/install.log &> /dev/null
then
    echo "Package $PACKAGE_NAME.deb seems to be correctly configured."
else
    echo "Package $PACKAGE_NAME.deb does not configure correctly. See \"postinst\" script in debconf folder."
    exit 1
fi

echo ""
echo "-----"
echo ""

apt purge -y $PACKAGE_NAME &> /tmp/uninstall.log
if [[ "$?" != "0" ]]; then
    echo "Error:"
    cat /tmp/uninstall.log
    exit 1
else
    echo "Package $PACKAGE_NAME.deb uninstalls sucessfully"
    echo "The current java version is:"
    java -version
fi

if grep update-alternatives /tmp/uninstall.log &> /dev/null
then
    echo "Package $PACKAGE_NAME.deb seems to be correctly de-configured."
else
    echo "Package $PACKAGE_NAME.deb is not deconfigured corectly. See \"prerm\" script in debconf folder."
    exit 1
fi
