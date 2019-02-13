# openjdk-builder
This repository is used to build .deb packages from OpenJDK source.

It is tested with the following source repositories:

 - <https://hg.openjdk.java.net/jdk8u>
 - <https://hg.openjdk.java.net/jdk/jdk11/>
 - <https://hg.openjdk.java.net/jdk/jdk12/>

## How to use

Clone this repository, cd to it and make a mercurial clone of the OpenJDK repo you want to build (hg clone <url/to/repo>).
Make sure you have a recent version of docker-engine installed and run:

`python3 run.py <jdk-version> <bootstrap-jdk-package> [--clean] [--no-test]`.

The jdk-version should be the name of the folder where the source is, e.g. jdk8u, and the bootstrap-jdk-package should be
an existing openjdk distribution from the debian package source, e.g. openjdk-8-jdk. According to OpenJDK a bootstrap-jdk
will work if it has version N-1 when you want to build version N. However openjdk-8-jdk works for jdk8u and openjdk-11-jdk
works for jdk11.

Make sure there is a folder with the same name as the source folder in the debconf folder, e.g. debconf/jdk8u. This folder
should contain configuration for the debmake program to create a debian package.

The flag `--clean` runs make clean in the source directory before make build.

The flag `--no-test` skips the install/uninstall test of the built package to test that posinst/prerm scripts seems correct.
This option has no effect if --no-pack is given.

The flag `--no-pack` skips the creation of the .deb package and only builds the source.
