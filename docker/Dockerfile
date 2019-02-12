FROM debian:stretch-slim
RUN apt update && apt dist-upgrade
RUN apt install -y build-essential zip unzip file man libx11-dev libxext-dev libxrender-dev libxrandr-dev libxtst-dev libxt-dev libcups2-dev libfontconfig1-dev libasound2-dev
RUN mkdir -p /usr/share/man/man1/
RUN echo "deb http://deb.debian.org/debian stretch-backports main" >> /etc/apt/sources.list
RUN apt update
ARG JDK_VERSION=openjdk-8-jdk
RUN apt install -y $JDK_VERSION
ADD run.sh /

