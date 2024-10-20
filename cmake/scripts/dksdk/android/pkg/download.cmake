##########################################################################
# File: dkcoder/cmake/scripts/dksdk/android/pkg/download.cmake            #
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

function(help)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "" "MODE" "")

    if(NOT ARG_MODE)
        set(ARG_MODE FATAL_ERROR)
    endif()

    message(${ARG_MODE} "usage: ./dk dksdk.android.pkg.download PACKAGES...

Downloads Android Command Line Tools and if needed a Java JDK as well,
accepts all Android licenses, and with the Command Line Tools'
[sdkmanager] installs the packages.

Only meant for CI use, after you have already accepted the terms
for Android elsewhere.

You may use a number sign (#) to encode a semicolon (;) since semicolons are
interpreted by CMake as separators. So for the following package:
   system-images;android-31;google_apis;x86_64
you can use
   system-images#android-31#google_apis#x86_64

Packages
========

Use `./dk dksdk.android.ndk.download` to download the following with
versions supported by DkSDK:

  Package                          | Description
  -------                          | -------
  ndk;VER                          | NDK (Side by side)
  platforms;android-VER            | Android SDK Platform

To use Android Studio's Device Manager, you will need other
packages using `./dk dksdk.android.pkg.download`:

  Package                                     | Description
  -------                                     | -------
  build-tools;VER                             | (1) Android SDK Build-Tools
  emulator                                    | (2) Android Emulator
  platform-tools                              | Android SDK Platform-Tools
  system-images;android-31;google_apis;x86_64 | (3) Google APIs Intel x86_64 Atom System Image

(1) 'Android SDK Build-Tools' package: It will be auto-downloaded by
the Android Gradle Plugin during a build so you shouldn't need to download it
with `./dk dksdk.android.pkg.download`

(2) You don't need this if you can run your Android application on a physical
Android device.

(3) The choice of architecture (Intel x86_64) is specific to your machine,
and the Android API version must be compatible with your Android source code's
build.gradle [minSdk].

Directory Structure
===================

Places the package within .ci/local/share/android-sdk:

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
    └── patcher
    
Proxies
=======

The Android SDK Manager, which is used to download the Android packages,
supports HTTP proxies. If your environment must use an HTTP proxy to
download from the Internet, you can set the environment variable 'http_proxy'
to the URL of your HTTP proxy.
Examples: http://proxy_host:3182 or http://proxy_host:8080.
Authenticated proxies with a username and password are not supported.
Set the environment variable 'https_proxy' if you have a
https://proxy_host:proxy_port proxy.

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

set(sdkmanager_NAMES sdkmanager sdkmanager.bat)

# Sets SDKMANAGER and SDKMANAGER_COMMON_ARGS.
# SDKMANAGER_COMMON_ARGS is used for no-authentication proxy settings.
function(find_sdkmanager)
    set(noValues REQUIRED NO_SYSTEM_PATH)
    set(singleValues)
    set(multiValues)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")

    set(find_ARGS)
    if(ARG_NO_SYSTEM_PATH)
        list(APPEND find_ARGS NO_DEFAULT_PATH)
    endif()
    if(ARG_REQUIRED)
        list(APPEND find_ARGS REQUIRED)
    endif()

    set(hints "${CMAKE_SOURCE_DIR}/.ci/local/share/android-sdk/cmdline-tools/latest/bin")
    find_program(SDKMANAGER NAMES ${sdkmanager_NAMES} HINTS ${hints} ${find_ARGS})

    # Any HTTP proxy? We follow the curl standards at https://everything.curl.dev/usingcurl/proxies/env
    # which do not allow HTTP_PROXY.
    set(proxy_ARGS)
    if(DEFINED ENV{http_proxy})
        set(url "$ENV{http_proxy}")
        if(url MATCHES [[^http://([^:]+):([0-9]+).*]])
            list(APPEND proxy_ARGS --no_https --proxy=http "--proxy_host=${CMAKE_MATCH_1}" --proxy_port=${CMAKE_MATCH_2})
        endif()
    elseif(DEFINED ENV{https_proxy} OR DEFINED ENV{HTTPS_PROXY})
        if(DEFINED ENV{https_proxy})
            set(url "$ENV{https_proxy}")
        else()
            set(url "$ENV{HTTPS_PROXY}")
        endif()
        if(url MATCHES [[^https://([^:]+):([0-9]+).*]])
            list(APPEND proxy_ARGS --proxy=http "--proxy_host=${CMAKE_MATCH_1}" --proxy_port=${CMAKE_MATCH_2})
        endif()
    endif()

    set(SDKMANAGER_COMMON_ARGS "${proxy_ARGS}" PARENT_SCOPE)
endfunction()

function(install_sdkmanager)
    set(noValues NO_SYSTEM_PATH)
    set(singleValues)
    set(multiValues)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")

    # NO_SYSTEM_PATH
    set(expand_NO_SYSTEM_PATH)
    if(ARG_NO_SYSTEM_PATH)
        list(APPEND expand_NO_SYSTEM_PATH NO_SYSTEM_PATH)
    endif()

    find_sdkmanager(${expand_NO_SYSTEM_PATH})

    if(NOT SDKMANAGER)
        # Download into .ci/local/share/android-sdk/cmdline-tools/latest/bin (which is one of the HINTS)
        if(CMAKE_HOST_WIN32)
            set(url https://dl.google.com/android/repository/commandlinetools-win-9477386_latest.zip)
            message(${loglevel} "Downloading Android Command Line Tools from ${url}")
            file(DOWNLOAD "${url}"
                "${CMAKE_CURRENT_BINARY_DIR}/commandlinetools.zip"
                EXPECTED_HASH SHA256=696431978daadd33a28841320659835ba8db8080a535b8f35e9e60701ab8b491)
        elseif(CMAKE_HOST_UNIX)
            set(url https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip)
            message(${loglevel} "Downloading Android Command Line Tools from ${url}")
            file(DOWNLOAD "${url}"
                "${CMAKE_CURRENT_BINARY_DIR}/commandlinetools.zip"
                EXPECTED_HASH SHA256=bd1aa17c7ef10066949c88dc6c9c8d536be27f992a1f3b5a584f9bd2ba5646a0)
        else()
            message(FATAL_ERROR "Your platform is currently not supported by this download script")
        endif()

        message(${loglevel} "Extracting Android Command Line Tools")
        file(ARCHIVE_EXTRACT INPUT "${CMAKE_CURRENT_BINARY_DIR}/commandlinetools.zip"
            DESTINATION "${CMAKE_CURRENT_BINARY_DIR}")
        file(REMOVE_RECURSE "${CMAKE_SOURCE_DIR}/.ci/local/share/android-sdk/cmdline-tools")
        file(MAKE_DIRECTORY "${CMAKE_SOURCE_DIR}/.ci/local/share/android-sdk/cmdline-tools")
        # Do file(RENAME) but work across mount volumes (ex. inside containers)
        file(GLOB entries
            LIST_DIRECTORIES true
            RELATIVE "${CMAKE_CURRENT_BINARY_DIR}/cmdline-tools"
            "${CMAKE_CURRENT_BINARY_DIR}/cmdline-tools/*")
        foreach(entry IN LISTS entries)
            file(COPY "${CMAKE_CURRENT_BINARY_DIR}/cmdline-tools/${entry}"
                DESTINATION "${CMAKE_SOURCE_DIR}/.ci/local/share/android-sdk/cmdline-tools/latest"
                FOLLOW_SYMLINK_CHAIN
                USE_SOURCE_PERMISSIONS)
        endforeach()
        file(REMOVE_RECURSE "${CMAKE_CURRENT_BINARY_DIR}/cmdline-tools")
    endif()

    find_sdkmanager(${expand_NO_SYSTEM_PATH} REQUIRED)
endfunction()

function(are_google_licenses_accepted LICENSEDIR)
    set(licenses android-googletv-license android-sdk-arm-dbt-license android-sdk-license android-sdk-preview-license google-gdk-license mips-android-sysimage-license)

    set(accepted OFF PARENT_SCOPE)

    foreach(license IN LISTS licenses)
        if(NOT EXISTS "${LICENSEDIR}/${license}")
            return()
        endif()
    endforeach()

    set(accepted ON PARENT_SCOPE)
endfunction()

macro(set_run_sdkmanager)
    set(run_sdkmanager "${CMAKE_COMMAND}" -E env "JAVA_HOME=${JAVA_HOME}" ${SDKMANAGER})
endmacro()

function(accept_google_licenses)
    are_google_licenses_accepted(${CMAKE_SOURCE_DIR}/.ci/local/share/android-sdk/licenses)

    set_run_sdkmanager()
    if(NOT accepted)
        string(REPEAT "Y\n" 20 many_yes)
        file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/yes-licenses" "${many_yes}")
        execute_process(
            COMMAND ${run_sdkmanager} --licenses ${SDKMANAGER_COMMON_ARGS}
            INPUT_FILE "${CMAKE_CURRENT_BINARY_DIR}/yes-licenses"
            COMMAND_ERROR_IS_FATAL ANY)
    endif()
endfunction()

# DESCRIPTION: It is nice although not required to use the description
#   without any version suffix given in:
#     $env:JAVA_HOME="$PWD\.ci\local\share\jdk"
#     Y:\source\scoutapps\us\SonicScoutAndroid\.ci\local\share\android-sdk\cmdline-tools\latest\bin\sdkmanager.bat --list_installed
function(install_pkg)
    set(noValues)
    set(singleValues DESCRIPTION PACKAGE)
    set(multiValues)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")

    # Unencode number signs (#) into semicolons (;)
    string(REPLACE "#" ";" pkg "${ARG_PACKAGE}")

    # Install into .ci/local/share/android-sdk ...
    message(${loglevel} "Installing ${ARG_DESCRIPTION}")
    set_run_sdkmanager()
    execute_process(
        COMMAND ${run_sdkmanager} --install ${SDKMANAGER_COMMON_ARGS} "${pkg}"
        COMMAND_ERROR_IS_FATAL ANY)
endfunction()

function(run)
    # Get helper functions from this file
    include(${CMAKE_CURRENT_FUNCTION_LIST_FILE})

    set(noValues HELP QUIET NO_SYSTEM_PATH)
    set(singleValues PACKAGE)
    set(multiValues)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")

    if(ARG_HELP)
        help(MODE NOTICE)
        return()
    endif()

    # PACKAGE
    if(ARG_PACKAGE)
        set(pkg "${ARG_PACKAGE}")
    else()
        help(MODE NOTICE)
        message(FATAL_ERROR "The PACKAGE argument is required.")
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

    # Get helper functions from JDK downlader
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../java/jdk/download.cmake")

    # gitignore
    file(MAKE_DIRECTORY "${CMAKE_SOURCE_DIR}/.ci/local/share/android-sdk")
    file(COPY_FILE
        "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../../__dk-tmpl/all.gitignore"
        "${CMAKE_SOURCE_DIR}/.ci/local/share/android-sdk/.gitignore"
        ONLY_IF_DIFFERENT)

    install_java_jdk(${expand_NO_SYSTEM_PATH})
    get_jdk_home(JDK_VERSION 17) # Set JAVA_HOME if available. Android Gradle requires 17, so check for that first.
    install_sdkmanager(${expand_NO_SYSTEM_PATH})

    accept_google_licenses()
    install_pkg(PACKAGE "${pkg}")
endfunction()
