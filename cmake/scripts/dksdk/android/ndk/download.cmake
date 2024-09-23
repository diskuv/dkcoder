##########################################################################
# File: dkcoder/cmake/scripts/dksdk/android/ndk/download.cmake            #
#                                                                        #
# Copyright 2023 Diskuv, Inc.                                            #
#                                                                        #
# Licensed under the Open Software License version 3.0                   #
# (the "License"); you may not use this file except in compliance        #
# with the License. You may obtain a copy of the License at              #
#                                                                        #
#     https://opensource.org/license/osl-3-0-php/                        #
#                                                                        #
##########################################################################

set(NDK_LTS 23.1.7779620)
set(SDK_PLATFORM 33)

function(help)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "" "MODE" "")

    if(NOT ARG_MODE)
        set(ARG_MODE FATAL_ERROR)
    endif()

    message(${ARG_MODE} "usage: ./dk dksdk.android.ndk.download

Downloads versions of 'NDK (Side by side) ${NDK_LTS}' and 'Android SDK Platform ${SDK_PLATFORM}'
packages supported by DkSDK, and if needed accepts licenses and downloads
a Java JDK and Android SDK Manager as well.

Only meant for CI use, after you have already accepted the terms
for Android NDK elsewhere.

When using the Android NDK you will need to have Ninja in your
PATH to complete builds; alternatively Android CMake installations
contain Ninja and Android NDK does search within Android CMake,
even if you have explicitly chosen a different CMake with cmake.dir
in your local.properties.

We recommend that you use:
    ./dk dksdk.android.cmake.download
to download an Android CMake version containing Ninja.

Packages
========

The following packages are downloaded with versions supported by DkSDK:

  Package                          | Description
  -------                          | -------
  ndk;${NDK_LTS}                          | NDK (Side by side)
  platforms;android-${SDK_PLATFORM}            | Android SDK Platform

The Android SDK Platform (ex. adb.exe) is downloaded so Android Studio can
recognize the directory structure (described below) as a valid choice of
'Android SDK Location'.

However, to use Android Studio's Device Manager, you will need other
packages using `./dk dksdk.android.pkg.download`:

  Package                                     | Description
  -------                                     | -------
  emulator                                    | Android Emulator
  platform-tools                              | Android SDK Platform-Tools
  system-images;android-31;google_apis;x86_64 | Google APIs Intel x86_64 Atom System Image

Directory Structure
===================

Places the NDK in .ci/local/share/android-sdk:

.ci/local/share/
└── android-sdk
    ├── cmdline-tools
    │   └── latest
    │       ├── bin
    │       ├── lib
    │       └── source.properties
    ├── licenses
    │   ├── android-googletv-license
    │   ├── ...
    │   └── mips-android-sysimage-license
    ├── ndk
    │   └── ${NDK_LTS}
    │       ├── build
    │       ├── CHANGELOG.md
    │       ├── meta
    │       ├── ndk-build
    │       ├── ndk-gdb
    │       ├── ndk-lldb
    │       ├── ndk-stack
    │       ├── ndk-which
    │       ├── NOTICE
    │       ├── NOTICE.toolchain
    │       ├── package.xml
    │       ├── prebuilt
    │       ├── python-packages
    │       ├── README.md
    │       ├── shader-tools
    │       ├── simpleperf
    │       ├── source.properties
    │       ├── sources
    │       ├── toolchains
    │       └── wrap.sh
    │── patcher
    └── platforms
        └── android-${SDK_PLATFORM}
            ├── android.jar
            ├── android-stubs-src.jar
            ├── build.prop
            ├── core-for-system-modules.jar
            ├── data
            ├── framework.aidl
            ├── optional
            ├── package.xml
            ├── sdk.properties
            ├── skins
            ├── source.properties
            ├── templates
            └── uiautomator.jar

Arguments
=========

HELP
  Print this help message.

QUIET
  Do not print CMake STATUS messages.

NO_SYSTEM_PATH
  Do not check for a JDK in well-known locations and in the PATH.
  Instead, install a JDK if no JDK exists at `.ci/local/share/jdk`.
")
endfunction()

function(install_sdk_platform)
    set(ANDROID_JAR ${CMAKE_SOURCE_DIR}/.ci/local/share/android-sdk/platforms/android-${SDK_PLATFORM}/android.jar)

    if(NOT EXISTS ${ANDROID_JAR})
        install_pkg(NAME "Android SDK Platform" PACKAGE "platforms;android-${SDK_PLATFORM}")
    endif()

    set(ANDROID_JAR "${ANDROID_JAR}" PARENT_SCOPE)
endfunction()

function(install_ndk)
    set(ANDROID_TOOLCHAIN_FILE ${CMAKE_SOURCE_DIR}/.ci/local/share/android-sdk/ndk/${NDK_LTS}/build/cmake/android.toolchain.cmake)

    if(NOT EXISTS ${ANDROID_TOOLCHAIN_FILE})
        install_pkg(NAME "NDK (Side by side)" PACKAGE "ndk;${NDK_LTS}")
    endif()

    set(ANDROID_TOOLCHAIN_FILE "${ANDROID_TOOLCHAIN_FILE}" PARENT_SCOPE)
endfunction()

function(run)
    # Get helper functions from this file
    include(${CMAKE_CURRENT_FUNCTION_LIST_FILE})

    cmake_parse_arguments(PARSE_ARGV 0 ARG "HELP;QUIET;NO_SYSTEM_PATH" "" "")

    if(ARG_HELP)
        help(MODE NOTICE)
        return()
    endif()

    # QUIET
    if(ARG_QUIET)
        set(loglevel DEBUG)
    else()
        set(loglevel STATUS)
    endif()

    # NO_SYSTEM_PATH
    set(expand_NO_SYSTEM_PATH)
    if(ARG_NO_SYSTEM_PATH)
        list(APPEND expand_NO_SYSTEM_PATH NO_SYSTEM_PATH)
    endif()

    # Get helper functions (install_java_jdk, get_jdk_home) from JDK downlader
    include(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../java/jdk/download.cmake)

    # Get helper functions (install_sdkmanager, accept_licenses) from Android pkg downlader
    include(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../pkg/download.cmake)

    # gitignore
    file(MAKE_DIRECTORY "${CMAKE_SOURCE_DIR}/.ci/local/share/android-sdk")
    file(COPY_FILE
        "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../../__dk-tmpl/all.gitignore"
        "${CMAKE_SOURCE_DIR}/.ci/local/share/android-sdk/.gitignore"
        ONLY_IF_DIFFERENT)

    install_java_jdk(${expand_NO_SYSTEM_PATH})
    get_jdk_home() # Set JAVA_HOME if available
    install_sdkmanager(${expand_NO_SYSTEM_PATH})

    accept_google_licenses()
    install_sdk_platform()
    install_ndk()
    message(${loglevel} "Android SDK Platform JAR is at: ${ANDROID_JAR}")
    message(${loglevel} "Android toolchain file is at: ${ANDROID_TOOLCHAIN_FILE}")
endfunction()
