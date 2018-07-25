# Android development environment for ubuntu.
# version 0.0.5

FROM ubuntu

MAINTAINER mattysaw <matthew.m.sawyer@gmail.com>

# Specially for SSH access and port redirection
ENV ROOTPASSWORD android

# Expose ADB, ADB control and VNC ports
EXPOSE 22
EXPOSE 5037
EXPOSE 5554
EXPOSE 5555
EXPOSE 5900

ENV DEBIAN_FRONTEND noninteractive
RUN echo "debconf shared/accepted-oracle-license-v1-1 select true" | debconf-set-selections && \
    echo "debconf shared/accepted-oracle-license-v1-1 seen true" | debconf-set-selections

# Update packages
RUN apt-get -y update && \
    apt-get -y install software-properties-common bzip2 ssh net-tools openssh-server socat curl unzip libgl1-mesa-dev libqt5gui5 libpulse0 && \
    add-apt-repository ppa:webupd8team/java && \
    apt-get update && \
    apt-get -y install oracle-java8-installer && \
    rm -rf /var/lib/apt/lists/*

# Install android sdk
RUN curl -O https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip && \
    unzip sdk-tools-linux-4333796.zip -d /usr/local/ && \
    rm sdk-tools-linux-4333796.zip && \
    mkdir /usr/local/android-sdk && \
    mv /usr/local/tools /usr/local/android-sdk/tools && \
    chown -R root:root /usr/local/android-sdk/

# Add android tools and platform tools to PATH
ENV ANDROID_HOME /usr/local/android-sdk
ENV ANDROID_SDK_ROOT $ANDROID_HOME
ENV PATH $PATH:$ANDROID_HOME/tools
ENV PATH $PATH:$ANDROID_HOME/tools/bin
ENV PATH $PATH:$ANDROID_HOME/platform-tools

# Export JAVA_HOME variable
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

# Install latest android tools and system images
RUN ls /usr/local/android-sdk/tools/bin && yes | sdkmanager --licenses && \
    sdkmanager "platform-tools" "platforms;android-28" "system-images;android-28;google_apis_playstore;x86" "emulator"

# Create fake keymap file
RUN mkdir /usr/local/android-sdk/tools/keymaps && \
    touch /usr/local/android-sdk/tools/keymaps/en-us

# Run sshd
RUN mkdir /var/run/sshd && \
    echo "root:$ROOTPASSWORD" | chpasswd && \
    sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd && \
    echo "export VISIBLE=now" >> /etc/profile

ENV NOTVISIBLE "in users profile"

# Add entrypoint
ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
