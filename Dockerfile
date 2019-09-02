FROM openjdk:8

LABEL maintainer "yevhen.piotrovskyi@gmail.com"

ENV DEBIAN_FRONTEND noninteractive

# Android & Gradle
ENV GRADLE_URL http://services.gradle.org/distributions/gradle-3.3-all.zip
ENV GRADLE_HOME /usr/local/gradle-3.3
ENV ANDROID_SDK_URL http://dl.google.com/android/android-sdk_r24.3.3-linux.tgz
ENV ANDROID_HOME /usr/local/android-sdk-linux
ENV ANDROID_SDK_COMPONENTS_LATEST platform-tools,build-tools-23.0.1,build-tools-25.0.3,android-23,android-25,extra-android-support,extra-android-m2repository,extra-google-m2repository
ENV PATH ${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools

# NodeJS
ENV NPM_CONFIG_LOGLEVEL info
ENV NODE_VERSION_NAME latest-dubnium
ENV NODE_VERSION 10.x

#Ruby
ENV RUBY_MAJOR 2.5
ENV RUBY_VERSION 2.5.1
ENV RUBY_DOWNLOAD_SHA256 886ac5eed41e3b5fc699be837b0087a6a5a3d10f464087560d2d21b3e71b754d
ENV RUBYGEMS_VERSION 3.0.6
ENV BUNDLER_VERSION 1.15.3

ENV SDK_URL="https://dl.google.com/android/repository/sdk-tools-linux-3859397.zip" \
    ANDROID_HOME="/usr/local/android-sdk" \
    ANDROID_VERSION=28 \
    ANDROID_BUILD_TOOLS_VERSION=27.0.3

ENV FASTLANE_VERSION 2.130.0

# Download Android SDK
RUN mkdir "$ANDROID_HOME" .android \
    && cd "$ANDROID_HOME" \
    && curl -o sdk.zip $SDK_URL \
    && unzip sdk.zip \
    && rm sdk.zip \
    && mkdir "$ANDROID_HOME/licenses" || true \
    && echo "24333f8a63b6825ea9c5514f83c2829b004d1fee" > "$ANDROID_HOME/licenses/android-sdk-license" \
    && yes | $ANDROID_HOME/tools/bin/sdkmanager --licenses

# Install Android Build Tool and Libraries
RUN $ANDROID_HOME/tools/bin/sdkmanager --update > /dev/null
RUN $ANDROID_HOME/tools/bin/sdkmanager "build-tools;${ANDROID_BUILD_TOOLS_VERSION}" \
    "platforms;android-${ANDROID_VERSION}" \
    "platform-tools"  > /dev/null

# Install Build Essentials
RUN apt-get update && apt-get install build-essential -y && apt-get install file -y && apt-get install apt-utils -y

RUN apt-get update && \
    apt-get -y install zip expect && \
    curl -sL https://deb.nodesource.com/setup_${NODE_VERSION} | bash - && \
    apt-get install -y nodejs

# skip installing gem documentation
RUN mkdir -p /usr/local/etc \
  && { \
    echo 'install: --no-document'; \
    echo 'update: --no-document'; \
  } >> /usr/local/etc/gemrc

RUN set -ex \
  \
  && buildDeps=' \
    bison \
    libgdbm-dev \
    ruby \
    autoconf bison build-essential libssl-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm3 libgdbm-dev \
  ' \
  && apt-get install -y libtool libyaml-dev imagemagick \
  && apt-get install -y --no-install-recommends $buildDeps \
  && rm -rf /var/lib/apt/lists/* \
  && wget -O ruby.tar.xz "https://cache.ruby-lang.org/pub/ruby/${RUBY_MAJOR%-rc}/ruby-$RUBY_VERSION.tar.xz" \
  && echo "$RUBY_DOWNLOAD_SHA256 *ruby.tar.xz" | sha256sum -c - \
  && mkdir -p /usr/src/ruby \
  && tar -xJf ruby.tar.xz -C /usr/src/ruby --strip-components=1 \
  && rm ruby.tar.xz \
  && cd /usr/src/ruby \
  # hack in "ENABLE_PATH_CHECK" disabling to suppress:
  #   warning: Insecure world writable dir
  && { \
    echo '#define ENABLE_PATH_CHECK 0'; \
    echo; \
    cat file.c; \
  } > file.c.new \
  && mv file.c.new file.c \
  \
  && autoconf \
  && ./configure --disable-install-doc --enable-shared \
  && make -j"$(nproc)" \
  && make install \
  \
  && cd / \
  && rm -r /usr/src/ruby \
  \
  && gem update --system "$RUBYGEMS_VERSION"

# install things globally, for great justice
# and don't create ".bundle" in all our apps
ENV GEM_HOME /usr/local/bundle
ENV BUNDLE_PATH="$GEM_HOME" \
  BUNDLE_BIN="$GEM_HOME/bin" \
  BUNDLE_SILENCE_ROOT_WARNING=1 \
  BUNDLE_APP_CONFIG="$GEM_HOME"
RUN mkdir -p "$GEM_HOME" "$BUNDLE_BIN" \
  && chmod 777 "$GEM_HOME" "$BUNDLE_BIN"

# Path
ENV PATH $PATH:$BUNDLE_BIN:${ANDROID_HOME}/tools:$ANDROID_HOME/platform-tools:${GRADLE_HOME}/bin

RUN gem install fastlane -v ${FASTLANE_VERSION} \
  && gem install fastlane-plugin-appicon fastlane-plugin-android_change_string_app_name fastlane-plugin-humanable_build_number \
  && gem update --system "$RUBYGEMS_VERSION"

# Remove Build Deps
RUN apt-get purge -y --auto-remove $buildDeps

# Output versions
RUN node -v && npm -v && ruby -v && fastlane -v
