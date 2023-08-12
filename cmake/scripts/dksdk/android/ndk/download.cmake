##########################################################################
# File: dktool/cmake/scripts/dksdk/android/ndk/download.cmake            #
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

function(help)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "" "MODE" "")

    if(NOT ARG_MODE)
        set(ARG_MODE FATAL_ERROR)
    endif()

    message(${ARG_MODE} "usage: ./dk dksdk.android.ndk.download

Downloads Android NDK ${NDK_LTS}. Only meant for CI use, after you have
already accepted the terms for Android NDK elsewhere.

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
    │   └── 23.1.7779620
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
    └── patcher

Arguments
=========

HELP
  Print this help message.

QUIET
  Do not print CMake STATUS messages.
")
endfunction()

set(sdkmanager_NAMES sdkmanager sdkmanager.bat)
function(install_sdkmanager)
    set(hints ${CMAKE_SOURCE_DIR}/.ci/local/share/android-sdk/cmdline-tools/latest/bin)
    find_program(SDKMANAGER NAMES ${sdkmanager_NAMES} HINTS ${hints})

    if(NOT SDKMANAGER)
        # Download into .ci/local/share/android-sdk/cmdline-tools/latest/bin (which is one of the HINTS)
        if(CMAKE_HOST_WIN32)
            set(url https://dl.google.com/android/repository/commandlinetools-win-9477386_latest.zip)
            message(${loglevel} "Downloading Android NDK from ${url}")
            file(DOWNLOAD ${url}
                ${CMAKE_CURRENT_BINARY_DIR}/commandlinetools.zip
                EXPECTED_HASH SHA256=696431978daadd33a28841320659835ba8db8080a535b8f35e9e60701ab8b491)
        elseif(CMAKE_HOST_UNIX)
            set(url https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip)
            message(${loglevel} "Downloading Android NDK from ${url}")
            file(DOWNLOAD ${url}
                ${CMAKE_CURRENT_BINARY_DIR}/commandlinetools.zip
                EXPECTED_HASH SHA256=bd1aa17c7ef10066949c88dc6c9c8d536be27f992a1f3b5a584f9bd2ba5646a0)
        else()
            message(FATAL_ERROR "Your platform is currently not supported by this download script")
        endif()

        message(${loglevel} "Extracting Android NDK")
        file(ARCHIVE_EXTRACT INPUT ${CMAKE_CURRENT_BINARY_DIR}/commandlinetools.zip
            DESTINATION ${CMAKE_CURRENT_BINARY_DIR})
        file(REMOVE_RECURSE ${CMAKE_SOURCE_DIR}/.ci/local/share/android-sdk/cmdline-tools)
        file(MAKE_DIRECTORY ${CMAKE_SOURCE_DIR}/.ci/local/share/android-sdk/cmdline-tools)
        # Do file(RENAME) but work across mount volumes (ex. inside containers)
        file(GLOB entries
            LIST_DIRECTORIES true
            RELATIVE ${CMAKE_CURRENT_BINARY_DIR}/cmdline-tools
            ${CMAKE_CURRENT_BINARY_DIR}/cmdline-tools/*)
        foreach(entry IN LISTS entries)
            file(COPY ${CMAKE_CURRENT_BINARY_DIR}/cmdline-tools/${entry}
                DESTINATION ${CMAKE_SOURCE_DIR}/.ci/local/share/android-sdk/cmdline-tools/latest
                USE_SOURCE_PERMISSIONS)
        endforeach()
        file(REMOVE_RECURSE "${CMAKE_CURRENT_BINARY_DIR}/cmdline-tools")
    endif()

    find_program(SDKMANAGER NAMES ${sdkmanager_NAMES} REQUIRED HINTS ${hints})
endfunction()

function(are_licenses_accepted LICENSEDIR)
    set(licenses android-googletv-license android-sdk-arm-dbt-license android-sdk-license android-sdk-preview-license google-gdk-license mips-android-sysimage-license)

    set(accepted OFF PARENT_SCOPE)

    foreach(license IN LISTS licenses)
        if(NOT EXISTS "${LICENSEDIR}/${license}")
            return()
        endif()
    endforeach()

    set(accepted ON PARENT_SCOPE)
endfunction()

function(install_ndk)
    set(hints ${CMAKE_SOURCE_DIR}/.ci/local/share/android-sdk/cmdline-tools/latest/bin)
    set(ANDROID_TOOLCHAIN_FILE ${CMAKE_SOURCE_DIR}/.ci/local/share/android-sdk/ndk/${NDK_LTS}/build/cmake/android.toolchain.cmake)

    if(NOT EXISTS ${ANDROID_TOOLCHAIN_FILE})
        # Install toolchain and the rest of the NDK into .ci/local/share/android-sdk ...

        # FIRST licenses have to be accepted
        are_licenses_accepted(${CMAKE_SOURCE_DIR}/.ci/local/share/android-sdk/licenses)

        set(run_sdkmanager ${CMAKE_COMMAND} -E env JAVA_HOME=${JAVA_HOME} ${SDKMANAGER})

        if(NOT accepted)
            string(REPEAT "Y\n" 20 many_yes)
            file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/yes-licenses" "${many_yes}")
            execute_process(
                COMMAND ${run_sdkmanager} --licenses
                INPUT_FILE ${CMAKE_CURRENT_BINARY_DIR}/yes-licenses
                COMMAND_ERROR_IS_FATAL ANY)
        endif()

        # SECOND install the NDK
        message(${loglevel} "Installing Android NDK")
        execute_process(
            COMMAND ${run_sdkmanager} --install "ndk;${NDK_LTS}"
            COMMAND_ERROR_IS_FATAL ANY)
    endif()

    set(ANDROID_TOOLCHAIN_FILE "${ANDROID_TOOLCHAIN_FILE}" PARENT_SCOPE)
endfunction()

function(run)
    # Get helper functions from this file
    include(${CMAKE_CURRENT_FUNCTION_LIST_FILE})

    set(CMAKE_CURRENT_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_CURRENT_FUNCTION}")

    cmake_parse_arguments(PARSE_ARGV 0 ARG "HELP;QUIET" "" "")

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

    # Get helper functions from JDK downlader
    include(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../java/jdk/download.cmake)

    install_java_jdk()
    get_jdk_home() # Set JAVA_HOME if available
    install_sdkmanager()
    install_ndk()
    message(STATUS "Android toolchain file is at: ${ANDROID_TOOLCHAIN_FILE}")
endfunction()
