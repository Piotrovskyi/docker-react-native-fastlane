FROM java:jdk

LABEL maintainer "yevhen.piotrovskyi@gmail.com"

ENV DEBIAN_FRONTEND noninteractive


################################################################################################
###
### Environment variables
###
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
ENV RUBY_MAJOR 2.3
ENV RUBY_VERSION 2.3.8
ENV RUBY_DOWNLOAD_SHA256 910f635d84fd0d81ac9bdee0731279e6026cb4cd1315bbbb5dfb22e09c5c1dfe
ENV RUBYGEMS_VERSION 3.0.1
ENV BUNDLER_VERSION 1.15.3

ENV SDK_URL="https://dl.google.com/android/repository/sdk-tools-linux-3859397.zip" \
    ANDROID_HOME="/usr/local/android-sdk" \
    ANDROID_VERSION=28 \
    ANDROID_BUILD_TOOLS_VERSION=27.0.3
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

# ################################################################################################
# ###
# ### Install Android SDK & Build Tools
# ###

# # Dependencies
# RUN dpkg --add-architecture i386 \
#   && apt-get update \
#   && apt-get install -yq libstdc++6:i386 zlib1g:i386 libncurses5:i386 ant maven --no-install-recommends \
#   && curl -L ${GRADLE_URL} -o /tmp/gradle-3.3-all.zip \
#   && unzip /tmp/gradle-3.3-all.zip -d /usr/local \
#   && rm /tmp/gradle-3.3-all.zip \
#   && curl -L ${ANDROID_SDK_URL} | tar xz -C /usr/local \
#   && mkdir -p  /usr/local/opt/ \
#   && ln -s /usr/local/android-sdk-linux /usr/local/opt/android-sdk \
#   && (while sleep 3; do echo "y"; done) | ${ANDROID_HOME}/tools/android update sdk --no-ui --all --filter "${ANDROID_SDK_COMPONENTS_LATEST}"

# RUN yes | ${ANDROID_HOME}/tools/bin/sdkmanager --licenses

################################################################################################
###
### Install NodeJS & NPM
###

# RUN groupadd --gid 1000 node \
#   && useradd --uid 1000 --gid node --shell /bin/bash --create-home node

# RUN set -ex \
#   && for key in \
#     9554F04D7259F04124DE6B476D5A82AC7E37093B \
#     94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
#     0034A06D9D9B0064CE8ADF6BF1747F4AD2306D93 \
#     FD3A5288F042B6850C66B31F09FE44734EB7990E \
#     71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
#     DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
#     B9AE9905FFD7803F25714661B63B535A4C206CA9 \
#     C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
#   ; do \
#     gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
#   done


# RUN curl -SLO "https://nodejs.org/dist/$NODE_VERSION_NAME/node-v$NODE_VERSION-linux-x64.tar.xz" \
#   && curl -SLO "https://nodejs.org/dist/$NODE_VERSION_NAME/SHASUMS256.txt.asc" \
#   && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
#   && grep " node-v$NODE_VERSION-linux-x64.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
#   && tar -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /usr/local --strip-components=1 \
#   && rm "node-v$NODE_VERSION-linux-x64.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
#   && ln -s /usr/local/bin/node /usr/local/bin/nodejs

RUN apt-get update && \
    apt-get -y install zip expect && \
    curl -sL https://deb.nodesource.com/setup_${NODE_VERSION} | bash - && \
    apt-get install -y nodejs

################################################################################################
###
### Install Ruby & bundler
###

# skip installing gem documentation
RUN mkdir -p /usr/local/etc \
  && { \
    echo 'install: --no-document'; \
    echo 'update: --no-document'; \
  } >> /usr/local/etc/gemrc

# some of ruby's build scripts are written in ruby
#   we purge system ruby later to make sure our final image uses what we just built
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
  \
  && wget -O ruby.tar.xz "https://cache.ruby-lang.org/pub/ruby/${RUBY_MAJOR%-rc}/ruby-$RUBY_VERSION.tar.xz" \
  && echo "$RUBY_DOWNLOAD_SHA256 *ruby.tar.xz" | sha256sum -c - \
  \
  && mkdir -p /usr/src/ruby \
  && tar -xJf ruby.tar.xz -C /usr/src/ruby --strip-components=1 \
  && rm ruby.tar.xz \
  \
  && cd /usr/src/ruby \
  \
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


# RUN gem install bundler --version "$BUNDLER_VERSION"

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


################################################################################################
###
### Install Fastlane and plugins
###

RUN gem install fastlane -NV \
  && gem install fastlane-plugin-appicon fastlane-plugin-android_change_string_app_name fastlane-plugin-humanable_build_number \
  && gem update --system "$RUBYGEMS_VERSION"

# Remove Build Deps
RUN apt-get purge -y --auto-remove $buildDeps

# Output versions
RUN node -v && npm -v && ruby -v && fastlane -v
