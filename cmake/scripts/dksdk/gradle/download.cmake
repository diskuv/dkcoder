##########################################################################
# File: dktool/cmake/scripts/dksdk/gradle/download.cmake                 #
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

    message(${ARG_MODE} "usage: ./dk dksdk.gradle.download

Downloads Gradle and if needed Java JDK as well.

Directory Structure
===================

Places Gradle in .ci/local/share/gradle:

.ci/local/share/
└── gradle
    ├── bin/
    │   ├── gradle
    │   └── gradle.bat
    └── lib/
        ├── agents/
        │   └── gradle-instrumentation-agent-8.2.1.jar
        ├── annotations-24.0.0.jar
        ├── ant-1.10.13.jar
        ├── ...
        ├── plugins/
        │   ├── aws-java-sdk-core-1.12.365.jar
        │   ├── ...
        │   └── testng-6.3.1.jar
        └── xml-apis-1.4.01.jar

Arguments
=========

HELP
  Print this help message.

QUIET
  Do not print CMake STATUS messages.

NO_SYSTEM_PATH
  Do not check for Gradle in well-known locations and in the PATH.
  Instead, if no Gradle exists at `.ci/local/share/gradle`, then
  1. Install Gradle at `.ci/local/share/gradle`
  2. If the JDK hadn't been installed at `.ci/local/share/jdk`
     then install the JDK at `.ci/local/share/jdk`
")
endfunction()

function(install_java_gradle)
    set(noValues NO_SYSTEM_PATH)
    set(singleValues)
    set(multiValues)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")

    set(hints ${CMAKE_SOURCE_DIR}/.ci/local/share/gradle/bin)
    set(find_program_INITIAL)
    if(ARG_NO_SYSTEM_PATH)
        list(APPEND find_program_INITIAL NO_DEFAULT_PATH)
    endif()
    if(CMAKE_HOST_WIN32)
        set(GRADLE_FILENAME gradle.bat)
    else()
        set(GRADLE_FILENAME gradle)
    endif()
    find_program(GRADLE NAMES ${GRADLE_FILENAME} HINTS ${hints} ${find_program_INITIAL})

    if(NOT GRADLE)
        # Download into .ci/local/share/gradle/bin (which is one of the HINTS)
        if(CMAKE_HOST_UNIX OR CMAKE_HOST_WIN32)
            set(url https://services.gradle.org/distributions/gradle-8.3-bin.zip)
            message(${loglevel} "Downloading Gradle from ${url}")
            file(DOWNLOAD ${url}
                ${CMAKE_CURRENT_BINARY_DIR}/gradle.zip
                EXPECTED_HASH SHA256=591855b517fc635b9e04de1d05d5e76ada3f89f5fc76f87978d1b245b4f69225)
            message(${loglevel} "Extracting Gradle")
            file(ARCHIVE_EXTRACT INPUT ${CMAKE_CURRENT_BINARY_DIR}/gradle.zip
                DESTINATION ${CMAKE_CURRENT_BINARY_DIR})

            file(REMOVE_RECURSE ${CMAKE_CURRENT_BINARY_DIR}/gradle)
            file(RENAME ${CMAKE_CURRENT_BINARY_DIR}/gradle-8.3 ${CMAKE_CURRENT_BINARY_DIR}/gradle)
            file(REMOVE_RECURSE ${CMAKE_SOURCE_DIR}/.ci/local/share/gradle)
            file(COPY ${CMAKE_CURRENT_BINARY_DIR}/gradle DESTINATION ${CMAKE_SOURCE_DIR}/.ci/local/share)
        else()
            message(FATAL_ERROR "Your platform is currently not supported by this download script")
        endif()

        find_program(GRADLE NAMES ${GRADLE_FILENAME} REQUIRED HINTS ${hints})
    endif()
endfunction()

function(run)
    # Get helper functions from this file
    include(${CMAKE_CURRENT_FUNCTION_LIST_FILE})

    set(CMAKE_CURRENT_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_CURRENT_FUNCTION}")

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

    # Get helper functions from other commands
    include(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../java/jdk/download.cmake)

    # Do prereqs
    install_java_jdk(${expand_NO_SYSTEM_PATH})

    install_java_gradle(${expand_NO_SYSTEM_PATH}) # Set GRADLE
    message(STATUS "Gradle is at: ${GRADLE}")
endfunction()
