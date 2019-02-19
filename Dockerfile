# buggy with gtk+ issues when opening Eclipse dialog windows
#FROM openjdk:8u191-jre-alpine3.8
#FROM anapsix/alpine-java:8u202b08_jdk
FROM alpine:3.8

EXPOSE 8080 8000 5900 6080 32745

ENV DOCKER_VERSION=1.6.0 \
    MAVEN_VERSION=3.3.9 \
    TOMCAT_HOME=/home/user/tomcat8 \
    JAVA_VERSION=8u131 \
    JAVA_VERSION_PREFIX=1.8.0_131
    
ENV TERM xterm
ENV DISP_SIZE 1600x900x16
ENV DISPLAY :20.0
ENV M2_HOME=/home/user/apache-maven-$MAVEN_VERSION
ENV JAVA_HOME=/opt/jdk$JAVA_VERSION_PREFIX
ENV PATH=$JAVA_HOME/bin:$M2_HOME/bin:$PATH
ENV USER_NAME=user
ENV HOME=/home/user
ENV SWT_GTK3=1
ENV SWT_WEBKIT2=1
#ENV LANG=C.UTF-8

#ARG ECLIPSE_MIRROR=http://ftp.fau.de/eclipse/technology/epp/downloads/release/photon/R
ARG ECLIPSE_MIRROR=http://ftp.fau.de//eclipse/technology/epp/downloads/release/2019-03/M1
#ARG ECLIPSE_TAR=eclipse-cpp-photon-R-linux-gtk-x86_64.tar.gz
ARG ECLIPSE_TAR=eclipse-cpp-2019-03-M1-linux-gtk-x86_64.tar.gz
      
#    supervisor chromium icu-libs x11vnc xvfb subversion fluxbox xterm dbus-x11 libxext libxrender libxtst font-croscore && \
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories && \
    apk upgrade apk-tools && apk add --update ca-certificates bash openssh openssl shadow sudo wget unzip mc curl vim \
    supervisor icu-libs x11vnc xvfb subversion fluxbox xterm dbus-x11 libxext libxrender libxtst && \
    \
    echo "%root ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    rm -rf /tmp/* /var/cache/apk/* && \
    adduser -S user -h /home/user -s /bin/bash -G root -u 1000 && \
    echo "%root ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    usermod -p "*" user && \
    \
    sudo mkdir -p /opt/noVNC/utils/websockify && \
    wget -qO- "http://github.com/kanaka/noVNC/tarball/master" | sudo tar -zx --strip-components=1 -C /opt/noVNC && \
    wget -qO- "https://github.com/kanaka/websockify/tarball/master" | sudo tar -zx --strip-components=1 -C /opt/noVNC/utils/websockify && \
    \
    mkdir -p /home/user/KeepAlive && \
    \
    mkdir /home/user/cbuild /home/user/tomcat8 /home/user/apache-maven-$MAVEN_VERSION && \
    sudo wget -qO- "http://apache.ip-connect.vn.ua/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz" | tar -zx --strip-components=1 -C /home/user/apache-maven-$MAVEN_VERSION/ && \
    sudo wget -qO- "http://archive.apache.org/dist/tomcat/tomcat-8/v8.0.24/bin/apache-tomcat-8.0.24.tar.gz" | sudo tar -zx --strip-components=1 -C /home/user/tomcat8 && \
    sudo rm -rf /home/user/tomcat8/webapps/* && \
    \
    sudo mkdir -p /etc/pki/tls/certs && \
    sudo openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/pki/tls/certs/novnc.pem -out /etc/pki/tls/certs/novnc.pem -days 3650 \
         -subj "/C=PH/ST=Cebu/L=Cebu/O=NA/OU=NA/CN=codenvy.io" && \
    sudo chmod 444 /etc/pki/tls/certs/novnc.pem && \
    \
    sudo apk add --update adwaita-gtk2-theme gdk-pixbuf libxext-dev libxrender-dev libxtst-dev gtk+3.0 g++ gdb make && \
    sudo wget ${ECLIPSE_MIRROR}/${ECLIPSE_TAR} -O /tmp/eclipse.tar.gz -q && sudo tar -xf /tmp/eclipse.tar.gz -C /opt && sudo rm /tmp/eclipse.tar.gz && \
    sudo sed "s/@user.home\/eclipse-workspace/\/projects/g" -i /opt/eclipse/eclipse.ini && \
    \
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    apk add firefox-esr font-croscore adwaita-icon-theme adwaita-gtk2-theme && \
    \
    printf "export JAVA_HOME=/opt/jdk$JAVA_VERSION_PREFIX\
        \nexport M2_HOME=/home/user/apache-maven-$MAVEN_VERSION\
        \nexport TOMCAT_HOME=/home/user/tomcat8\
        \nexport PATH=$JAVA_HOME/bin:$M2_HOME/bin:$PATH\
        \nif [ ! -f /projects/KeepAlive/keepalive.html ]\nthen\
        \nsleep 5\ncp -rf /home/user/KeepAlive /projects\nfi" | sudo tee -a /home/user/.bashrc && \
    \
    cd /tmp && \
    curl -so /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
    curl -Lso /tmp/glibc-2.29-r0.apk https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.29-r0/glibc-2.29-r0.apk && \
    curl -Lso /tmp/glibc-bin-2.29-r0.apk https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.29-r0/glibc-bin-2.29-r0.apk && \
    curl -Lso /tmp/glibc-i18n-2.29-r0.apk https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.29-r0/glibc-i18n-2.29-r0.apk && \
    apk add --allow-untrusted /tmp/glibc-2.29-r0.apk /tmp/glibc-bin-2.29-r0.apk /tmp/glibc-i18n-2.29-r0.apk && \
    \
    rm /tmp/glibc-2.29-r0.apk && \
    rm /tmp/glibc-bin-2.29-r0.apk && \
    rm /tmp/glibc-i18n-2.29-r0.apk && \
    rm -rf /tmp/libz && \
    apk del curl glibc-i18n && \
    \
    wget -c --header "Cookie: oraclelicense=accept-securebackup-cookie" -qO- \
        http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION}-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-${JAVA_VERSION}-linux-x64.tar.gz | sudo tar -zx -C /opt/
#greybird-themes-gtk3 
#    /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 C.UTF-8 && \
#    echo "export LANG=C.UTF-8" > /etc/profile.d/locale.sh && \
#    /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc-compat/lib && \
#    \

ADD index.html  /opt/noVNC/
ADD supervisord.conf /opt/
ADD keepalive.html /home/user/KeepAlive
ADD --chown=user:root menu /home/user/.menu
ADD --chown=user:root init /home/user/.init
ADD --chown=user:root fonts.conf /home/user/.config/fontconfig/fonts.conf

USER user

WORKDIR /projects

ENV ECLIPSE_WORKSPACE=/projects
ENV ECLIPSE_DOT=/projects/.eclipse
ENV DELAY=50

CMD /usr/bin/supervisord -c /opt/supervisord.conf & sleep 365d
