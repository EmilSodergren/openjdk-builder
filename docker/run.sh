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
if [[ "$VERSION" = "jdk8u" ]]; then
    CONFIG_PARAMS="--with-milestone=emil --disable-debug-symbols --disable-zip-debug-info"
    PACKAGE_NAME="openjdk-1.8.0-emil"
elif [[ "$VERSION" = "jdk11" ]]; then
    TIME=`date '+%F-%H-%M-%S'`
    CONFIG_PARAMS="--with-version-opt=$TIME --with-version-pre=emil --disable-warnings-as-errors"
    PACKAGE_NAME="openjdk-11-emil"
elif [[ "$VERSION" = "jdk12" ]]; then
    TIME=`date '+%F-%H-%M-%S'`
    CONFIG_PARAMS="--with-version-opt=$TIME --with-version-pre=emil --disable-warnings-as-errors"
    PACKAGE_NAME="openjdk-12-emil"
elif [[ "$VERSION" = "jdk13" ]]; then
    TIME=`date '+%F-%H-%M-%S'`
    CONFIG_PARAMS="--with-version-opt=$TIME --with-version-pre=emil --disable-warnings-as-errors"
    PACKAGE_NAME="openjdk-13-emil"
elif [[ "$VERSION" = "jdk14" ]]; then
    TIME=`date '+%F-%H-%M-%S'`
    CONFIG_PARAMS="--with-version-opt=$TIME --with-version-pre=emil --disable-warnings-as-errors"
    PACKAGE_NAME="openjdk-14-emil"
elif [[ "$VERSION" = "jdk15" ]]; then
    TIME=`date '+%F-%H-%M-%S'`
    CONFIG_PARAMS="--with-version-opt=$TIME --with-version-pre=emil --disable-warnings-as-errors"
    PACKAGE_NAME="openjdk-15-emil"
else
    echo "The version $VERSION is not in the run.sh script."
    exit 1
fi

mkdir $PACKAGE_NAME

pushd /build > /dev/null
bash configure -q $CONFIG_PARAMS --with-native-debug-symbols=none --prefix=/$PACKAGE_NAME/usr/lib/
if [[ $CLEAN = 1 ]]; then
    make clean
fi
make images

if [[ $NO_PACK = 1 ]]; then
    exit 0
fi

make install

popd > /dev/null

rm -rf $PACKAGE_NAME/usr/lib/bin
cp -r /DEBIAN $PACKAGE_NAME
sed -i "s#{package_name}#$PACKAGE_NAME#g" `find $PACKAGE_NAME/DEBIAN -type f`

dpkg-deb --build $PACKAGE_NAME

if [[ $NO_TEST != 1 ]]; then

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
        echo "Package $PACKAGE_NAME.deb installs successfully"
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
        echo "Package $PACKAGE_NAME.deb uninstalls successfully"
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
fi

mv $PACKAGE_NAME.deb /packages/
