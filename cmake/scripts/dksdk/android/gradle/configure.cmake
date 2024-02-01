##########################################################################
# File: dktool/cmake/scripts/dksdk/android/gradle/configure.cmake        #
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

    message(${ARG_MODE} "usage: ./dk dksdk.android.gradle.configure

Sets local.properties for the Android Gradle Plugin.

The Android SDK manager is required to be present in either .ci/ or
on the PATH. Use `./dk dksdk.android.ndk.download` before this
command to ensure it is present.

By default any existing local.properties will not be overwritten.

Directory Structure
===================

local.properties

Arguments
=========

HELP
  Print this help message.

QUIET
  Do not print CMake STATUS messages.

OVERWRITE
  If local.properties already exists, overwrite it.
")
endfunction()

function(run)
    # Get helper functions from this file
    include(${CMAKE_CURRENT_FUNCTION_LIST_FILE})

    cmake_parse_arguments(PARSE_ARGV 0 ARG "HELP;QUIET;NO_SYSTEM_PATH;OVERWRITE" "" "")

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

    # OVERWRITE
    if(EXISTS "${CMAKE_SOURCE_DIR}/local.properties" AND NOT ARG_OVERWRITE)
        return()
    endif()
    
    # Get helper functions from other commands
    include(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../ndk/download.cmake)
    include(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../cmake/copy.cmake)

    set(content)

    # Find [sdkmanager] which should be in a <android-sdk>/cmdline-tools/{latest,<version>}/bin
    # directory
    find_sdkmanager(REQUIRED)
    cmake_path(GET SDKMANAGER PARENT_PATH android_sdk_DIR) # bin
    cmake_path(GET android_sdk_DIR PARENT_PATH android_sdk_DIR) # latest,<version>
    cmake_path(GET android_sdk_DIR PARENT_PATH android_sdk_DIR) # cmdline-tools
    cmake_path(GET android_sdk_DIR PARENT_PATH android_sdk_DIR) # <android-sdk>
    string(APPEND content "sdk.dir=${android_sdk_DIR}\n")
    message(${loglevel} "Android SDK: ${android_sdk_DIR}")

    # Find if there is a standalone cmake
    check_standalone_cmake(IS_STANDALONE STANDALONE_DIR)
    if(IS_STANDALONE)
        string(APPEND content "cmake.dir=${STANDALONE_DIR}\n")
        message(${loglevel} "CMake ${CMAKE_VERSION}: ${STANDALONE_DIR}")
    endif()

    file(WRITE "${CMAKE_SOURCE_DIR}/local.properties" "${content}")

    message(${loglevel} "Android Gradle Plugin settings saved to: local.properties")
endfunction()
