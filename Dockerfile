FROM fedora:39

ENV JMETER_VERSION=5.5
ENV JMETER_HOME=/opt/apache-jmeter-${JMETER_VERSION}
ENV PATH=$JMETER_HOME/bin:/usr/local/bin:/usr/bin:$PATH
ENV DISPLAY=:1
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk

# Install all required packages
RUN dnf -y upgrade --refresh && \
    dnf -y install \
    java-17-openjdk java-17-openjdk-devel \
    wget curl unzip tar gzip sudo findutils which \
    xorg-x11-server-Xvfb \
    x11vnc \
    fluxbox \
    xterm \
    net-tools \
    procps-ng \
    python3-pip \
    supervisor && \
    dnf clean all

# Install noVNC
RUN mkdir -p /opt/novnc && \
    curl -L -o /tmp/novnc.tar.gz https://github.com/novnc/noVNC/archive/v1.3.0.tar.gz && \
    tar -xzf /tmp/novnc.tar.gz --strip-components=1 -C /opt/novnc && \
    rm /tmp/novnc.tar.gz && \
    curl -L -o /tmp/websockify.tar.gz https://github.com/novnc/websockify/archive/v0.10.0.tar.gz && \
    mkdir -p /opt/novnc/utils/websockify && \
    tar -xzf /tmp/websockify.tar.gz --strip-components=1 -C /opt/novnc/utils/websockify && \
    rm /tmp/websockify.tar.gz

# Install JMeter
RUN mkdir -p /opt && \
    wget https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-${JMETER_VERSION}.tgz -O /tmp/apache-jmeter.tgz && \
    tar -xzf /tmp/apache-jmeter.tgz -C /opt && \
    rm /tmp/apache-jmeter.tgz

# Install JMeter plugins
RUN mkdir -p $JMETER_HOME/lib/ext && \
    wget -q https://jmeter-plugins.org/files/packages/jpgc-graphs-basic-2.0.zip -O /tmp/jpgc-graphs-basic.zip && \
    unzip -q /tmp/jpgc-graphs-basic.zip -d $JMETER_HOME && \
    rm /tmp/jpgc-graphs-basic.zip

# Supervisor configuration with x11vnc
RUN mkdir -p /etc/supervisord.d && \
    echo "[unix_http_server]" > /etc/supervisord.d/supervisord.conf && \
    echo "file=/run/supervisor/supervisor.sock" >> /etc/supervisord.d/supervisord.conf && \
    echo "chmod=0700" >> /etc/supervisord.d/supervisord.conf && \
    echo "" >> /etc/supervisord.d/supervisord.conf && \
    echo "[supervisord]" >> /etc/supervisord.d/supervisord.conf && \
    echo "logfile=/var/log/supervisord.log" >> /etc/supervisord.d/supervisord.conf && \
    echo "pidfile=/var/run/supervisord.pid" >> /etc/supervisord.d/supervisord.conf && \
    echo "nodaemon=true" >> /etc/supervisord.d/supervisord.conf && \
    echo "" >> /etc/supervisord.d/supervisord.conf && \
    echo "[rpcinterface:supervisor]" >> /etc/supervisord.d/supervisord.conf && \
    echo "supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface" >> /etc/supervisord.d/supervisord.conf && \
    echo "" >> /etc/supervisord.d/supervisord.conf && \
    echo "[supervisorctl]" >> /etc/supervisord.d/supervisord.conf && \
    echo "serverurl=unix:///run/supervisor/supervisor.sock" >> /etc/supervisord.d/supervisord.conf && \
    echo "" >> /etc/supervisord.d/supervisord.conf && \
    echo "[program:xvfb]" >> /etc/supervisord.d/supervisord.conf && \
    echo "command=/usr/bin/Xvfb :1 -screen 0 1920x1080x24" >> /etc/supervisord.d/supervisord.conf && \
    echo "autorestart=true" >> /etc/supervisord.d/supervisord.conf && \
    echo "priority=10" >> /etc/supervisord.d/supervisord.conf && \
    echo "[program:x11vnc]" >> /etc/supervisord.d/supervisord.conf && \
    echo "command=/usr/bin/x11vnc -display :1 -nopw -forever -shared -rfbport 5901" >> /etc/supervisord.d/supervisord.conf && \
    echo "autorestart=true" >> /etc/supervisord.d/supervisord.conf && \
    echo "priority=20" >> /etc/supervisord.d/supervisord.conf && \
    echo "[program:fluxbox]" >> /etc/supervisord.d/supervisord.conf && \
    echo "command=/usr/bin/fluxbox" >> /etc/supervisord.d/supervisord.conf && \
    echo "environment=DISPLAY=:1" >> /etc/supervisord.d/supervisord.conf && \
    echo "autorestart=true" >> /etc/supervisord.d/supervisord.conf && \
    echo "priority=30" >> /etc/supervisord.d/supervisord.conf && \
    echo "[program:novnc]" >> /etc/supervisord.d/supervisord.conf && \
    echo "command=/opt/novnc/utils/novnc_proxy --vnc localhost:5901 --listen 0.0.0.0:6080" >> /etc/supervisord.d/supervisord.conf && \
    echo "autorestart=true" >> /etc/supervisord.d/supervisord.conf && \
    echo "priority=40" >> /etc/supervisord.d/supervisord.conf

# Create startup script
RUN echo '#!/bin/bash' > /startup.sh && \
    echo 'mkdir -p /run/supervisor /var/log /var/run/supervisor ~/.vnc' >> /startup.sh && \
    echo 'chmod 755 /run/supervisor' >> /startup.sh && \
    echo 'touch ~/.vnc/passwd && chmod 600 ~/.vnc/passwd' >> /startup.sh && \
    echo 'exec /usr/bin/supervisord -c /etc/supervisord.d/supervisord.conf' >> /startup.sh && \
    chmod +x /startup.sh

# Create non-root user
RUN useradd -ms /bin/bash jmeter && \
    echo "jmeter:jmeter" | chpasswd && \
    echo "jmeter ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    mkdir -p /jmeter && \
    chown -R jmeter:jmeter /opt /jmeter /var/log /var/run/supervisor /run/supervisor && \
    chmod -R 775 /jmeter

EXPOSE 5901 6080
WORKDIR /jmeter
USER jmeter
ENTRYPOINT ["/startup.sh"]
