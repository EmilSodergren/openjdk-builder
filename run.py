#!/usr/bin/python3
from os.path import exists, join
import os
import re
import sys
from string import Template
from sys import exit
from subprocess import call, Popen
from shutil import copy
from argparse import ArgumentParser
from os.path import basename
import json

ver_nr = re.compile(r"^jdk(\d*)u?$")


def getConfDirFromVersion(v):
    version_number = ver_nr.match(v)
    if version_number:
        version_number = int(version_number.group(1))
    else:
        print("Could not parse an integer from {}".format(v))
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


required_keys = ['base_image', 'maintainer_name', 'maintainer_email', 'version_pre']

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
parser.add_argument('--chown',
                    action='store_const',
                    const='--chown',
                    help='Change owner of the build artifacts to the user running the docker container')
args = parser.parse_args()

args.bootstrap_jdk_package = basename(args.bootstrap_jdk_package)

v = args.source_version

if not exists(v):
    print('No such version exists')
    exit(1)

with open("info.json") as f:
    params = json.load(f)
    if not all(key in params.keys() for key in required_keys):
        print("ERROR: Required key is not present in info.json")
        print("Needs:\n" + "\t\n".join(required_keys))
        sys.exit(1)

templ_map = {'USER_ID': str(os.getuid()), 'GROUP_ID': str(os.getgid()), 'BASE_IMAGE': params["base_image"]}
with open("docker/Dockerfile.in") as f:
    docker_file = Template(f.read())
    with open("docker/Dockerfile", 'w') as outf:
        outf.write(docker_file.safe_substitute(templ_map))

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

cmd = [
    "docker", "run", "--rm", "-t", "--entrypoint", "/run.sh", "-v", "/etc/timezone:/etc/timezone:ro", "-v", build_mount, "-v", config_mount,
    "-v", package_mount, "-e", "VERSION=" + v, "-e", "MAINTAINER_NAME=\"{}\"".format(params["maintainer_name"]), "-e",
    "MAINTAINER_EMAIL={}".format(params["maintainer_email"]), "-e", "VERSION_PRE={}".format(params["version_pre"]), docker_build_name,
    "--tag", args.tag, args.clean or "", args.no_test or "", args.no_pack or "", args.chown or ""
]
print(re.sub("--[^r^e][^m].*", "", " ".join(cmd).replace("-t", "-it").replace("/run.sh", "bash")))
call(cmd)
