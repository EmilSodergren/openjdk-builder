from os.path import exists, join
import os
from sys import exit
from subprocess import call, Popen
from argparse import ArgumentParser

parser = ArgumentParser(description='Setup the machine')

parser.add_argument('source_version', help='Version of JDK to build, needs to correspond to the folder name')
parser.add_argument('bootstrap_jdk_package', help='Which version to use as bootstrap JDK, by spec this should most of the time be JDK version N-1')
parser.add_argument('--clean', '-c', action='store_const', const='--clean', help='Should the old binaries be removed before build')
parser.add_argument('--no-test', action='store_const', const='--no-test', help='Skip testing the install/remove of the .deb package, this option will have no effect if --no-pack is used.')
parser.add_argument('--no-pack', action='store_const', const='--no-pack', help='Skip install and debmake steps, only build the source')
args = parser.parse_args()

v = args.source_version

if not exists(v):
    print('No such version exists')
    exit(1)

docker_build_name = "jdk_builder_"+v
p = Popen(["docker", "build", "--build-arg", "JDK_VERSION="+args.bootstrap_jdk_package, "-t", docker_build_name, "."], cwd="./docker")
p.wait()
build_mount = join(os.getcwd(), v)+":/build"
config_mount = join(os.getcwd(), "debconf", v)+":/DEBIAN"
packagedir = join(os.getcwd(), "packages")
if not os.path.exists(packagedir):
    os.makedirs(packagedir)
package_mount = join(os.getcwd(), "packages")+":/packages"
call(["docker","run","-t","-v", build_mount,"-v", config_mount, "-v", package_mount, "-e", "VERSION="+v, docker_build_name, "/run.sh", args.clean or "", args.no_test or "", args.no_pack or ""])
