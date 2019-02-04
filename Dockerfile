FROM openjdk:8u191-jdk-alpine3.8
#FROM openjdk:8u191-jre-alpine3.8

EXPOSE 8080 8000 5900 6080 32745

ENV LANG=C.UTF-8 \
    DOCKER_VERSION=1.6.0 \
    DOCKER_BUCKET=get.docker.com \
    CHE_IN_CONTAINER=true \
    MAVEN_VERSION=3.3.9 \
    TOMCAT_HOME=/home/user/tomcat8
ENV TERM xterm
ENV DISP_SIZE 1600x900x16
ENV DISPLAY :20.0
ENV M2_HOME=/home/user/apache-maven-$MAVEN_VERSION
ENV PATH=$M2_HOME/bin:$PATH
ENV USER_NAME=user
ENV HOME=/home/${USER_NAME}

#ARG ECLIPSE_MIRROR=http://ftp.fau.de/eclipse/technology/epp/downloads/release/photon/R
ARG ECLIPSE_MIRROR=https://www.eclipse.org/downloads/download.php?file=/technology/epp/downloads/release/neon/3
#ARG ECLIPSE_TAR=eclipse-cpp-photon-R-linux-gtk-x86_64.tar.gz
ARG ECLIPSE_TAR=eclipse-committers-neon-3-linux-gtk-x86_64.tar.gz&r=1

RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    apk upgrade apk-tools && \
    apk add --update ca-certificates bash openssh openssl shadow  \
    dialog sudo wget unzip mc curl vim supervisor \
    x11vnc xvfb subversion fluxbox rxvt-unicode terminus-font dbus-x11 socat libxext libxrender libxtst && \
    curl -sSL "https://${DOCKER_BUCKET}/builds/Linux/x86_64/docker-${DOCKER_VERSION}" -o /usr/bin/docker && \
    chmod +x /usr/bin/docker && \
    echo "%root ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    rm -rf /tmp/* /var/cache/apk/* && \
    adduser -S user -h /home/user -s /bin/bash -G root -u 1000 && \
    echo "%root ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    usermod -p "*" user && \
    sudo mkdir -p /home/user/KeepAlive &&\
    mkdir /home/user/cbuild /home/user/tomcat8 /home/user/apache-maven-$MAVEN_VERSION && \
    sudo wget -qO- "http://apache.ip-connect.vn.ua/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz" | tar -zx --strip-components=1 -C /home/user/apache-maven-$MAVEN_VERSION/ && \
    sudo wget -qO- "http://archive.apache.org/dist/tomcat/tomcat-8/v8.0.24/bin/apache-tomcat-8.0.24.tar.gz" | sudo tar -zx --strip-components=1 -C /home/user/tomcat8 && \
    sudo rm -rf /home/user/tomcat8/webapps/* && \
    sudo mkdir -p /opt/noVNC/utils/websockify && \
    wget -qO- "http://github.com/kanaka/noVNC/tarball/master" | sudo tar -zx --strip-components=1 -C /opt/noVNC && \
    wget -qO- "https://github.com/kanaka/websockify/tarball/master" | sudo tar -zx --strip-components=1 -C /opt/noVNC/utils/websockify && \
    sudo mkdir -p /etc/pki/tls/certs && \
    sudo openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/pki/tls/certs/novnc.pem -out /etc/pki/tls/certs/novnc.pem -days 3650 \
         -subj "/C=PH/ST=Cebu/L=Cebu/O=NA/OU=NA/CN=codenvy.io" && \
    sudo chmod 444 /etc/pki/tls/certs/novnc.pem && \
    sudo apk add --update libxext-dev libxrender-dev libxtst-dev gtk+3.0 libcanberra-gtk3 g++ gdb cmake && \
    sudo wget ${ECLIPSE_MIRROR}/${ECLIPSE_TAR} -O /tmp/eclipse.tar.gz -q && sudo tar -xf /tmp/eclipse.tar.gz -C /opt && sudo rm /tmp/eclipse.tar.gz && \
    sudo sed "s/@user.home/\/projects/g" -i /opt/eclipse/eclipse.ini && \
    printf "export JAVA_HOME=/opt/jdk$JAVA_VERSION_PREFIX\n\
export M2_HOME=/home/user/apache-maven-$MAVEN_VERSION\n\
export TOMCAT_HOME=/home/user/tomcat8\n\
export PATH=$JAVA_HOME/bin:$M2_HOME/bin:$PATH\n\
if [ ! -f /projects/KeepAlive/keepalive.html ]\nthen\nsleep 5\ncp -rf /home/user/KeepAlive /projects\nfi\n\
sudo date >> /home/user/date.log" | sudo tee -a /home/user/.bashrc

RUN ALPINE_GLIBC_BASE_URL="https://github.com/sgerrand/alpine-pkg-glibc/releases/download" && \
    ALPINE_GLIBC_PACKAGE_VERSION="2.25-r0" && \
    ALPINE_GLIBC_BASE_PACKAGE_FILENAME="glibc-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_BIN_PACKAGE_FILENAME="glibc-bin-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_I18N_PACKAGE_FILENAME="glibc-i18n-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    apk add --no-cache --virtual=.build-dependencies wget ca-certificates && \
    wget \
        "https://raw.githubusercontent.com/andyshinn/alpine-pkg-glibc/master/sgerrand.rsa.pub" \
        -O "/etc/apk/keys/sgerrand.rsa.pub" && \
    wget \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    apk add --no-cache \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    \
    rm "/etc/apk/keys/sgerrand.rsa.pub" && \
    /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 C.UTF-8 || true && \
    echo "export LANG=C.UTF-8" > /etc/profile.d/locale.sh && \
    \
    apk del glibc-i18n && \
    \
    rm "/root/.wget-hsts" && \
    apk del .build-dependencies && \
    rm \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME"
        
ADD index.html  /opt/noVNC/
ADD supervisord.conf /opt/
ADD keepalive.html /home/user/KeepAlive
ADD --chown=user:root menu /home/user/.menu
ADD --chown=user:root init /home/user/.init

USER user

WORKDIR /projects

ENV ECLIPSE_WORKSPACE=/projects/eclipse-workspace
ENV ECLIPSE_DOT=/projects/.eclipse
ENV DELAY=50

CMD /usr/bin/supervisord -c /opt/supervisord.conf & sleep 365d
