##########################################################################
# File: dktool\cmake\scripts\dksdk\android\cmake\download.cmake          #
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

# > Configure project :ffi-java-android-standalone
# [error] [CXX1416] Could not find Ninja on PATH or in SDK CMake bin folders.
# [CXX1416] Could not find Ninja on PATH or in SDK CMake bin folders.

# cmake;3.22.1

# Latest version of CMake supported by Android Studio.
# Consult with: .ci\local\share\android-sdk\cmdline-tools\latest\bin\sdkmanager.bat --list
set(CMAKE_LATEST 3.22.1)

function(help)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "" "MODE" "")

    if(NOT ARG_MODE)
        set(ARG_MODE FATAL_ERROR)
    endif()

    message(${ARG_MODE} "usage: ./dk dksdk.android.cmake.download

Downloads Android CMake ${CMAKE_LATEST} and if needed Java JDK as well.

Android CMake contains the Ninja build tool. Downloading Android CMake
is one of two ways to satisfy the requirement that Ninja be available
when building projects with Android NDK; the other way is to place Ninja
in the PATH. Even if you have explicitly chosen a different CMake with
cmake.dir in your local.properties, Android NDK will still consider the
Ninja contained in Android CMake.

Only meant for CI use, after you have already accepted the terms
for Android CMake elsewhere.

Directory Structure
===================

Places the CMake in .ci/local/share/android-sdk:

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
    └── cmake
        └── ${CMAKE_LATEST}
            ├── bin
            │   ├── cmake
            │   ├── cmcldeps
            │   ├── cpack
            │   ├── ctest
            │   └── ninja
            ├── doc/
            ├── package.xml
            ├── share/
            └── source.properties

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

function(install_android_cmake)
    set(exe_EXT)
    if(CMAKE_HOST_WIN32)
        set(exe_EXT .exe)
    endif()
    set(ANDROID_CMAKE ${CMAKE_SOURCE_DIR}/.ci/local/share/android-sdk/cmake/${CMAKE_LATEST}/bin/cmake${exe_EXT})

    if(NOT EXISTS ${ANDROID_CMAKE})
        # Install toolchain and the rest of the NDK into .ci/local/share/android-sdk ...

        # FIRST licenses have to be accepted
        are_licenses_accepted(${CMAKE_SOURCE_DIR}/.ci/local/share/android-sdk/licenses)

        set(run_sdkmanager ${CMAKE_COMMAND} -E env JAVA_HOME=${JAVA_HOME} ${SDKMANAGER})

        if(NOT accepted)
            string(REPEAT "Y\n" 20 many_yes)
            file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/yes-licenses" "${many_yes}")
            execute_process(
                COMMAND ${run_sdkmanager} --licenses ${SDKMANAGER_COMMON_ARGS}
                INPUT_FILE ${CMAKE_CURRENT_BINARY_DIR}/yes-licenses
                COMMAND_ERROR_IS_FATAL ANY)
        endif()

        # SECOND install the NDK
        message(${loglevel} "Installing Android CMake")
        execute_process(
            COMMAND ${run_sdkmanager} --install ${SDKMANAGER_COMMON_ARGS} "cmake;${CMAKE_LATEST}"
            COMMAND_ERROR_IS_FATAL ANY)
    endif()

    set(ANDROID_CMAKE "${ANDROID_CMAKE}" PARENT_SCOPE)
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

    # Get helper functions from JDK downlader
    include(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../java/jdk/download.cmake)
    # Get helper functions from Android NDK
    include(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../ndk/download.cmake)

    # gitignore
    file(MAKE_DIRECTORY "${CMAKE_SOURCE_DIR}/.ci/local/share/android-sdk")
    file(COPY_FILE
        "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../../__dk-tmpl/all.gitignore"
        "${CMAKE_SOURCE_DIR}/.ci/local/share/android-sdk/.gitignore"
        ONLY_IF_DIFFERENT)

    install_java_jdk(${expand_NO_SYSTEM_PATH})
    get_jdk_home() # Set JAVA_HOME if available
    install_sdkmanager(${expand_NO_SYSTEM_PATH})
    install_android_cmake()
    message(${loglevel} "Android CMake is at: ${ANDROID_CMAKE}")
endfunction()
