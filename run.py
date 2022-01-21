#!/usr/bin/python3
from os.path import exists, join
import os
import re
import sys
from sys import exit
from subprocess import call, Popen
from argparse import ArgumentParser
from os.path import basename
from shutil import copy
import json

ver_nr = re.compile(r"^jdk(\d*)u?")


def getConfDirFromVersion(v):
    version_number = None
    try:
        version_number = int(ver_nr.match(v)[1])
    except NameError:
        print("{} Could not be parsed as an integer".format(version_number))
        sys.exit(2)

    if version_number < 11:
        return 'jdk8u'
    elif version_number < 12:
        return 'jdk11'
    elif version_number < 14:
        return 'jdk12-13'
    elif version_number < 15:
        return 'jdk14'
    else:
        return 'jdk15-'


required_keys = ['maintainer_name', 'maintainer_email', 'version_pre']

parser = ArgumentParser(description='Setup the machine')

parser.add_argument('source_version', help='Version of JDK to build, needs to correspond to the folder name')
parser.add_argument('bootstrap_jdk_package',
                    help='Which version to use as bootstrap JDK, by spec this should most of the time be JDK version N-1')
parser.add_argument('--tag', '-t', required=True, help='What tag of the jdk should be built, this will also be part of the package name')
parser.add_argument('--clean', '-c', action='store_const', const='--clean', help='Should the old binaries be removed before build')
parser.add_argument('--no-test',
                    action='store_const',
                    const='--no-test',
                    help='Skip testing the install/remove of the .deb package, this option will have no effect if --no-pack is used.')
parser.add_argument('--no-pack', action='store_const', const='--no-pack', help='Skip install and debmake steps, only build the source')
args = parser.parse_args()

args.bootstrap_jdk_package = basename(args.bootstrap_jdk_package)

v = args.source_version

if not exists(v):
    print('No such version exists')
    exit(1)

docker_build_name = "jdk_builder_" + v
copy(join(os.getcwd(), "packages", args.bootstrap_jdk_package), join(os.getcwd(), "docker"))
p = Popen(["docker", "build", "--build-arg", "JDK_PACKAGE=" + args.bootstrap_jdk_package, "-t", docker_build_name, "."], cwd="./docker")
p.wait()
os.remove(join(os.getcwd(), "docker", args.bootstrap_jdk_package))
build_mount = join(os.getcwd(), v) + ":/build"
config_mount = join(os.getcwd(), "debconf", getConfDirFromVersion(v)) + ":/DEBIAN"
packagedir = join(os.getcwd(), "packages")
if not os.path.exists(packagedir):
    os.makedirs(packagedir)
package_mount = join(os.getcwd(), "packages") + ":/packages"
f = open("info.json")
params = json.load(f)
if not all(key in params.keys() for key in required_keys):
    print("ERROR: Required key is not present in info.json")
    print("Needs:\n" + "\t\n".join(required_keys))
    sys.exit(1)
cmd = [
    "docker", "run", "-t", "-v", build_mount, "-v", config_mount, "-v", package_mount, "-e", "VERSION=" + v, "-e",
    "MAINTAINER_NAME=\"{}\"".format(params["maintainer_name"]), "-e", "MAINTAINER_EMAIL={}".format(params["maintainer_email"]), "-e",
    "VERSION_PRE={}".format(params["version_pre"]), docker_build_name, "/run.sh", "--tag", args.tag, args.clean or "", args.no_test or "",
    args.no_pack or ""
]
print(re.sub("--.*", "", " ".join(cmd).replace("-t", "-it").replace("/run.sh", "")))
call(cmd)
