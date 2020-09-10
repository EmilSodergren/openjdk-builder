FROM debian:buster-slim
RUN apt update && apt dist-upgrade -y
RUN apt install -y build-essential zip unzip file man libx11-dev libxext-dev libxrender-dev libxrandr-dev libxtst-dev libxt-dev libcups2-dev libfontconfig1-dev libasound2-dev autoconf java-common
RUN mkdir -p /usr/share/man/man1/
RUN echo "deb http://deb.debian.org/debian stretch-backports main" >> /etc/apt/sources.list
RUN apt update
ARG JDK_PACKAGE
ADD $JDK_PACKAGE /
RUN dpkg -i /$JDK_PACKAGE
ADD run.sh /

