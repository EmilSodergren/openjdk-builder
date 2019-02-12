from os.path import exists, join
import os
from sys import exit
from subprocess import call, Popen
from argparse import ArgumentParser

parser = ArgumentParser(description='Setup the machine')

parser.add_argument('source_version', help='Version of JDK to build, needs to correspond to the folder name')
parser.add_argument('bootstrap_jdk_package', help='Which version to use as bootstrap JDK, by spec this should most of the time be JDK version N-1')
parser.add_argument('--clean', '-c', action='store_true')
args = parser.parse_args()

v = args.source_version

if not exists(v):
    print('No such version exists')
    exit(1)

docker_build_name = "jdk_builder_"+v
p = Popen(["docker", "build", "--build-arg", "JDK_VERSION="+args.bootstrap_jdk_package, "-t", docker_build_name, "."], cwd="./docker")
p.wait()
clean = ""
if (args.clean):
    clean = "--clean"
builddir = join(os.getcwd(), v)+":/build"
confdir = join(os.getcwd(), "debconf", v, "DEBIAN")+":/DEBIAN"
packagedir = join(os.getcwd(), "packages")+":/packages"
call(["docker","run","-t","-v", builddir,"-v", confdir, "-v", packagedir, "-e", "VERSION="+v, docker_build_name, "/run.sh", clean])
