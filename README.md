# Docker React Native Fastlane
Image for build React native android apps using Fastlane inside the docker container with no efforts

https://hub.docker.com/r/piotrovskyi/react-native-fastlane

## Status
[![Build Status](https://travis-ci.org/Piotrovskyi/docker-react-native-fastlane.png)](https://travis-ci.org/Piotrovskyi/docker-react-native-fastlane)

## Components
```
Built on openjdk version 8
```

| Component Name | Version |
|:---------------|--------:|
|gradle|3.3|
|android-sdk|24.3.3|
|build-tools|27.0.3|
|nodejs|10.x|
|ruby|2.5.1|
|gems|3.0.6|
|bundler|1.15.3|
|fastlane|2.129.0|

## Usage

Release Build
```
docker run -it -v /path/to/your/react-native/project/:/build -w /build android-fastlane-docker:latest /bin/sh -c "cd android && ./gradlew assembleRelease"
```

Fastlane Alpha
```
docker run -it -v /path/to/your/react-native/project/:/build -w /build android-fastlane-docker:latest /bin/sh -c "fastlane android alpha"
```
