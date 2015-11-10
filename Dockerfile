FROM ohmygoshjosh/ctr-base:3.2

# CONFIGURE JAVA
# Inspired by https://registry.hub.docker.com/u/jeanblanchard/java/ and
# https://github.com/jeanblanchard/docker-java
# ------------------------------------------------------------------------------

# Java Version
ENV JAVA_VERSION_MAJOR 8
ENV JAVA_VERSION_MINOR 60
ENV JAVA_VERSION_BUILD 27
ENV JAVA_PACKAGE       server-jre

# Copy all checksums from local to the container
# TIP: Be sure to copy the entire output of "sha256sum", not just the SHA itself.
# To compute a new checksum in the future...
# - Log into the Alpine Linux container with "docker run -it ohmygoshjosh/ctr-base" (run this on localdev)
# - Download the new file
# - "sha256sum <new-file_name>"
# - Write the new checksum into the appropriately named file in checksums/
COPY checksums /checksums

# Download and unarchive Java, then delete extraneous files
RUN apk add --update curl &&\
    mkdir -p /opt &&\
    curl -jksSLOH "Cookie: oraclelicense=accept-securebackup-cookie"\
    http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-b${JAVA_VERSION_BUILD}/${JAVA_PACKAGE}-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz &&\
    [ "$(cat /checksums/${JAVA_PACKAGE}-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz.sha256)" = "$(sha256sum ${JAVA_PACKAGE}-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz)" ] &&\
    gunzip -c ${JAVA_PACKAGE}-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz | tar -xf - -C /opt &&\
    ln -s /opt/jdk1.${JAVA_VERSION_MAJOR}.0_${JAVA_VERSION_MINOR} /opt/jdk &&\
    rm -rf /opt/jdk/*src.zip \
           /opt/jdk/lib/missioncontrol \
           /opt/jdk/lib/visualvm \
           /opt/jdk/lib/*javafx* \
           /opt/jdk/jre/lib/plugin.jar \
           /opt/jdk/jre/lib/ext/jfxrt.jar \
           /opt/jdk/jre/bin/javaws \
           /opt/jdk/jre/lib/javaws.jar \
           /opt/jdk/jre/lib/desktop \
           /opt/jdk/jre/plugin \
           /opt/jdk/jre/lib/deploy* \
           /opt/jdk/jre/lib/*javafx* \
           /opt/jdk/jre/lib/*jfx* \
           /opt/jdk/jre/lib/amd64/libdecora_sse.so \
           /opt/jdk/jre/lib/amd64/libprism_*.so \
           /opt/jdk/jre/lib/amd64/libfxplugins.so \
           /opt/jdk/jre/lib/amd64/libglass.so \
           /opt/jdk/jre/lib/amd64/libgstreamer-lite.so \
           /opt/jdk/jre/lib/amd64/libjavafx*.so \
           /opt/jdk/jre/lib/amd64/libjfx*.so &&\
    apk del curl &&\
    rm -rf /var/cache/apk/* &&\
    rm ${JAVA_PACKAGE}-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz

# Fix Java DNS resolution issue.
# See https://github.com/gliderlabs/docker-alpine/issues/11#issuecomment-106233554
RUN echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/v.conf

# Set environment
ENV JAVA_HOME /opt/jdk
ENV PATH ${PATH}:${JAVA_HOME}/bin

# DOWNLOAD ALL PLAY FRAMEWORK DEPENDENCIES BY PACKAGING A MINIMAL PROJECT
# ------------------------------------------------------------------------------
COPY minimal-play-scala/ /play/

# Launch activator on a minimal-play-java project.
# Afterward, clean up all files but leave downloaded libraries behind (in ~/.ivy2)
WORKDIR /play
RUN ./activator dist &&\
    rm -Rf /play
