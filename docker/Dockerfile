FROM debian:buster-slim
RUN apt update
RUN apt install -y apt-utils
RUN apt dist-upgrade -y
RUN apt install -y autoconf build-essential dialog file java-common libasound2-dev libcups2-dev libfontconfig1-dev libx11-dev libxext-dev libxrandr-dev libxrender-dev libxt-dev libxtst-dev man unzip zip
RUN mkdir -p /usr/share/man/man1/
ARG JDK_PACKAGE
ADD $JDK_PACKAGE /
RUN dpkg -i /$JDK_PACKAGE
ADD run.sh /

