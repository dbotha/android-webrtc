# Docker refresher:
# - docker build --progress=plain -t webrtc-android:0.0.1 .
# - docker run --rm -i -t --name webrtc-android webrtc-android:0.0.1 bash

# we explicitly specify an amd64 platform as I often build on Apple Silicon
# machines where the default of arm64 breaks things. I believe the alternative
# (and possibly better option) is to use NDK 24 and above, see:
# https://stackoverflow.com/a/69541958
FROM  --platform=linux/amd64 ubuntu:20.04 AS build

ENV ANDROID_SDK_ROOT /app/android-sdk-linux

WORKDIR /app

# Install dependencies to build the project
# include apt-get --no-install-recommends
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get --no-install-recommends -y install tzdata && \
    echo 'Europe/London' > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata

# An attempt is made to install snapcraft when webrtc's build/install_build_deps.sh
# is run in the cmake file. This will fail as snapd doesn't work in the Docker container.
# We can skip this failure though with the below - this is fine as libwebrtc doesn't
# actually need it
RUN echo 'db_get () { if [ "$@" = "snapcraft/snap-no-connectivity" ]; then RET="Skip"; else _db_cmd "GET $@"; fi }' >> /usr/share/debconf/confmodule && \
    apt-get --no-install-recommends -y install snapcraft

RUN apt-get --no-install-recommends -y install git lsb-release python rsync \
    emacs wget build-essential sudo pkg-config clang unzip openjdk-8-jdk ant  \
    android-sdk-platform-tools-common libncurses5 curl

RUN mkdir ${ANDROID_SDK_ROOT}

# ------------------------------------------------------
# --- Android SDK
RUN wget https://dl.google.com/android/repository/commandlinetools-linux-7583922_latest.zip && \
    unzip commandlinetools-linux-7583922_latest.zip && \
    mkdir ${ANDROID_SDK_ROOT}/cmdline-tools/ &&\
    mv cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools/latest && \
    rm commandlinetools-linux-7583922_latest.zip

ENV PATH ${PATH}:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin

RUN yes | sdkmanager --licenses

RUN touch /root/.android/repositories.cfg

# Platform tools
RUN yes | sdkmanager "platform-tools"

RUN yes | sdkmanager --update --channel=0

# Keep all sections in descending order!
RUN yes | sdkmanager \
    "platforms;android-30" \
    "build-tools;31.0.0" \
    "ndk;23.1.7779620" \
    "extras;android;m2repository" \
    "extras;google;m2repository" \
    "extras;google;google_play_services" \
    "add-ons;addon-google_apis-google-24"

ENV ANDROID_HOME ${ANDROID_SDK_ROOT}
ENV ANDROID_NDK_HOME=${ANDROID_SDK_ROOT}/ndk/23.1.7779620
ENV PATH ${PATH}:${ANDROID_NDK_HOME}:${ANDROID_HOME}/build-tools/31.0.0/

# Get gradle
RUN wget https://services.gradle.org/distributions/gradle-4.10.2-all.zip && \
    unzip gradle-4.10.2-all.zip
ENV GRADLE_HOME=/app/gradle-4.10.2
ENV PATH ${PATH}:${GRADLE_HOME}/bin

# Get CMake
COPY scripts/get_cmake.sh scripts/get_cmake.sh
RUN ./scripts/get_cmake.sh "3.25.1" linux /root
ENV PATH "/root/cmake/bin:$PATH"

# Get WebRTC
COPY scripts/get_webrtc.sh scripts/get_webrtc.sh
RUN ./scripts/get_webrtc.sh 108.5359.5.0 android /root /root

## Copy resources
COPY cmake cmake
COPY src src
COPY CMakeLists.txt ./

RUN cmake -B build  \
    -DCMAKE_TOOLCHAIN_FILE="${ANDROID_NDK_HOME}/build/cmake/android.toolchain.cmake" \
    -DANDROID_ABI=armeabi-v7a \
    -DANDROID_NATIVE_API_LEVEL=16 \
    -DBUILD_SHARED_LIBS=OFF \
    -DWebRTC_INCLUDE_DIR=/root/webrtc/include \
    -DWebRTC_LIBRARY=/root/webrtc/lib/armeabi-v7a/libwebrtc.a \
    -DCMAKE_BUILD_TYPE=Release

RUN cmake --build build --config Release --parallel $(nproc) --target AndroidWebRTC