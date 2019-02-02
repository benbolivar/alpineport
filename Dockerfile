FROM openjdk:8u191-jdk-alpine3.8
#FROM openjdk:12-ea-25-jdk-alpine3.8

ENV LANG=C.UTF-8 \
    DOCKER_VERSION=1.6.0 \
    DOCKER_BUCKET=get.docker.com \
    CHE_IN_CONTAINER=true \
    MAVEN_VERSION=3.3.9 \
    DISPLAY=:0.0 \
    DISPLAY_WIDTH=1920 \
    DISPLAY_HEIGHT=1080
ENV M2_HOME=/usr/lib/apache-maven-$MAVEN_VERSION
ENV PATH=${PATH}:${M2_HOME}/bin

RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    apk upgrade apk-tools && \
    apk add --update sudo curl ca-certificates bash openssh unzip openssl shadow git fluxbox supervisor x11vnc xterm xvfb socat libxext libxrender libxtst && \
    curl -sSL "https://${DOCKER_BUCKET}/builds/Linux/x86_64/docker-${DOCKER_VERSION}" -o /usr/bin/docker && \
    chmod +x /usr/bin/docker && \
    cd /tmp && \
    wget -q "http://apache.ip-connect.vn.ua/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz" && \
    tar -xzf "apache-maven-$MAVEN_VERSION-bin.tar.gz" && \
    mv "/tmp/apache-maven-$MAVEN_VERSION" "/usr/lib" && \
    echo "%root ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    rm -rf /tmp/* /var/cache/apk/* && \
    adduser -S user -h /home/user -s /bin/bash -G root -u 1000 && \
    echo "%root ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    usermod -p "*" user && \
    sudo git clone https://github.com/kanaka/noVNC.git /root/noVNC && \
    sudo git clone https://github.com/kanaka/websockify /root/noVNC/utils/websockify && \
    rm -rf /root/noVNC/.git && \
    rm -rf /root/noVNC/utils/websockify/.git && \
    apk del git && \
    sudo chown -R user /home/user/ && \
    sudo mkdir -p /home/user/.m2 && \
    sudo mkdir -p /home/user/jdtls/data && \
    sudo chgrp -R 0 ${HOME} && \
    sudo chmod -R g+rwX ${HOME} && \
    sudo mkdir -p /etc/pki/tls/certs && \
    sudo openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/pki/tls/certs/novnc.pem -out /etc/pki/tls/certs/novnc.pem -days 3650 \
         -subj "/C=PH/ST=Cebu/L=Cebu/O=NA/OU=NA/CN=codenvy.io" && \
    sudo chmod 444 /etc/pki/tls/certs/novnc.pem

ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf
ADD index.html /root/noVNC/index.html
ADD menu /home/user/menu

RUN sudo mkdir -p /home/user/KeepAlive
ADD keepalive.html /home/user/KeepAlive

EXPOSE 22 8000 8080 6080 32745

USER user

WORKDIR /projects

CMD /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf & sleep 365d
