import argparse
from os import environ, makedirs, cwd
from sys import exit
from subprocess import call
from datetime import datetime
import re

version = environ.get('VERSION')
version_pre = "emil"


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('-c', '--clean', action='store_true', help='Perform a clean build')
    parser.add_argument('-t', '--notest', action='store_true', help='Do not run install/uninstall test')
    parser.add_argument('-p', '--nopack', action='store_true', help='Do not create a deb-package')
    return parser.parse_args()


def main():

    args = parse_args()
    if version == "":
        exit(1)
    version_nr = re.search(r'jdk(\d{1,2}[u])', version).group(1)
    if version_nr == "":
        exit(1)
    config_params = "--with-version-opt={} --with-version-pre={} --disable-warnings-as-errors".format(
        datetime.now().strftime("%Y-%m-%d-%H-%M-%S"), version_pre)
    package_name = "openjdk-{}-{}".format(version_nr, version_pre)
    if version == "jdk8" or version == "jdk8u":
        config_params = "--with-milestone={} --disable-debug-symbols --disable-zip-debug-info".format(version_pre)
        package_name = "openjdk-1.8.0-{}".format(version_pre)

    makedirs("/{}/usr/lib/jvm/{}".format(package_name, package_name))
    cwd("/build")
    call(["bash", "configure", "-q", config_params, "--with-native-debug-symbols=none"])
    if args.clean:
        call(["make", "clean"])

    call(["make", "images"])

    if args.nopack:
        exit(0)


if __name__ == "__main__":
    main()
