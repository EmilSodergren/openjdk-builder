# openjdk-builder
This repository is used to build .deb packages from OpenJDK source.

It is tested with the following source repositories:

 - <https://hg.openjdk.java.net/jdk8u>
 - <https://github.com/openjdk/jdk11/>
 - <https://github.com/openjdk/jdk12/>
 - <https://github.com/openjdk/jdk15/>
 - <https://github.com/openjdk/jdk15u/>

## How to use

Clone this repository, cd to it and clone the OpenJDK repo you want to build (hg/git clone <url/to/repo>).
Make sure you have a recent version of docker-engine installed and run:

`python3 run.py <jdk-version> <bootstrap-jdk-package> --tag <tag> [--clean] [--no-test] [--no-pack]`.

The jdk-version should be the name of the folder where the source is, e.g. jdk11u, and the bootstrap-jdk-package should be
a prebuilt openjdk deb package. The bootstrap-jdk should be placed in the package folder. According to OpenJDK a bootstrap-jdk
will work if it has version N-1 when you want to build version N. However openjdk-8-jdk works for jdk8u and openjdk-11-jdk
works for jdk11.

Make sure there is a folder with the same name as the source folder in the debconf folder, e.g. debconf/jdk8u. This folder
should contain configuration for the debmake program to create a debian package.

The flag `--tag` is required and could be any tag, branch or commit hash in the source repo. This will be part of the name
of the built deb package.

The flag `--clean` runs make clean in the source directory before make build.

The flag `--no-test` skips the install/uninstall test of the built package to test that posinst/prerm scripts seems correct.
This option has no effect if --no-pack is given.

The flag `--no-pack` skips the creation of the .deb package and only builds the source.
